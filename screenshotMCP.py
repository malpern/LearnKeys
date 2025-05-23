from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import Literal, Optional
import subprocess
import tempfile
import os
import time
from fastapi.responses import JSONResponse

app = FastAPI()

# Define input schema for tool parameters
class ScreenshotRequest(BaseModel):
    mode: Literal["full", "app", "window", "display"]
    target: Optional[str] = None  # app name, window title, or display number

# Describe available tools
@app.get("/describe")
def describe_tool():
    return {
        "tools": [
            {
                "name": "take_screenshot",
                "description": (
                    "Captures a screenshot and returns the image file path. "
                    "Modes: 'full' for all displays, 'app' for app window by name, "
                    "'window' for window title (first match), 'display' for display number."
                ),
                "parameters": {
                    "type": "object",
                    "properties": {
                        "mode": {
                            "type": "string",
                            "enum": ["full", "app", "window", "display"],
                            "description": "Screenshot capture mode"
                        },
                        "target": {
                            "type": "string",
                            "description": (
                                "App name (for mode=app), window title (for mode=window), "
                                "or display number (for mode=display). Not used for mode=full."
                            )
                        }
                    },
                    "required": ["mode"]
                }
            }
        ]
    }

# Screenshot helpers
def capture_fullscreen(path: str):
    subprocess.run(["screencapture", "-x", path], check=True)

def capture_app_window(app_name: str, path: str):
    script = f'tell app "System Events" to get the id of the first window of process "{app_name}"'
    try:
        win_id = subprocess.check_output(["osascript", "-e", script], text=True).strip()
        subprocess.run(["screencapture", "-x", f"-l{win_id}", path], check=True)
    except subprocess.CalledProcessError:
        raise HTTPException(status_code=404, detail=f"Could not find window for app '{app_name}'.")

def capture_window_by_title(title: str, path: str):
    try:
        import Quartz
        from AppKit import NSImage
        window_list = Quartz.CGWindowListCopyWindowInfo(Quartz.kCGWindowListOptionOnScreenOnly, Quartz.kCGNullWindowID)
        match = next((w for w in window_list if title.lower() in str(w.get('kCGWindowName', '')).lower()), None)
        if not match:
            raise HTTPException(status_code=404, detail=f"No window found with title matching '{title}'.")
        window_id = match['kCGWindowNumber']
        subprocess.run(["screencapture", "-x", f"-l{window_id}", path], check=True)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

def capture_display(display_num: str, path: str):
    try:
        subprocess.run(["screencapture", "-x", f"-D{display_num}", path], check=True)
    except subprocess.CalledProcessError:
        raise HTTPException(status_code=400, detail=f"Failed to capture display {display_num}.")

def copy_to_clipboard(path: str):
    subprocess.run(["osascript", "-e", f'set the clipboard to (read (POSIX file "{path}") as JPEG picture)'], check=True)

# Entry point
@app.post("/run")
def run_tool(req: ScreenshotRequest):
    timestamp = int(time.time())
    temp_path = f"/tmp/ui-{timestamp}.png"

    if req.mode == "full":
        capture_fullscreen(temp_path)
    elif req.mode == "app":
        if not req.target:
            raise HTTPException(status_code=422, detail="Target (app name) required for 'app' mode.")
        capture_app_window(req.target, temp_path)
    elif req.mode == "window":
        if not req.target:
            raise HTTPException(status_code=422, detail="Target (window title) required for 'window' mode.")
        capture_window_by_title(req.target, temp_path)
    elif req.mode == "display":
        if not req.target:
            raise HTTPException(status_code=422, detail="Target (display number) required for 'display' mode.")
        capture_display(req.target, temp_path)
    else:
        raise HTTPException(status_code=400, detail=f"Unknown mode: {req.mode}")

    # Copy to clipboard
    copy_to_clipboard(temp_path)

    # Schedule cleanup after 60 seconds
    subprocess.Popen(["/bin/bash", "-c", f"sleep 60 && rm -f {temp_path} &"])

    return JSONResponse(content={"image_path": temp_path})
