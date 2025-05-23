#!/usr/bin/env python3

import asyncio
import subprocess
import tempfile
import time
from typing import Any, Sequence

from mcp.server.models import InitializationOptions
import mcp.types as types
from mcp.server import NotificationOptions, Server
import mcp.server.stdio


# Create the MCP server
server = Server("screenshot-server")


@server.list_tools()
async def handle_list_tools() -> list[types.Tool]:
    """List available screenshot tools."""
    return [
        types.Tool(
            name="take_screenshot",
            description=(
                "Captures a screenshot and returns the image file path. "
                "Modes: 'full' for all displays, 'app' for app window by name, "
                "'window' for window title (first match), 'display' for display number."
            ),
            inputSchema={
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
        )
    ]


@server.call_tool()
async def handle_call_tool(
    name: str, arguments: dict[str, Any] | None
) -> list[types.TextContent | types.ImageContent | types.EmbeddedResource]:
    """Handle tool calls."""
    if name != "take_screenshot":
        raise ValueError(f"Unknown tool: {name}")
    
    if not arguments:
        raise ValueError("Missing arguments")
    
    mode = arguments.get("mode")
    target = arguments.get("target")
    
    if not mode:
        raise ValueError("Missing required argument: mode")
    
    # Generate unique filename
    timestamp = int(time.time())
    temp_path = f"/tmp/ui-{timestamp}.png"
    
    try:
        if mode == "full":
            await capture_fullscreen(temp_path)
        elif mode == "app":
            if not target:
                raise ValueError("Target (app name) required for 'app' mode.")
            await capture_app_window(target, temp_path)
        elif mode == "window":
            if not target:
                raise ValueError("Target (window title) required for 'window' mode.")
            await capture_window_by_title(target, temp_path)
        elif mode == "display":
            if not target:
                raise ValueError("Target (display number) required for 'display' mode.")
            await capture_display(target, temp_path)
        else:
            raise ValueError(f"Unknown mode: {mode}")
        
        # Copy to clipboard
        await copy_to_clipboard(temp_path)
        
        # Schedule cleanup after 60 seconds
        asyncio.create_task(cleanup_file(temp_path, 60))
        
        return [
            types.TextContent(
                type="text",
                text=f"Screenshot captured successfully and saved to {temp_path}. Image has been copied to clipboard."
            )
        ]
        
    except Exception as e:
        return [
            types.TextContent(
                type="text", 
                text=f"Error capturing screenshot: {str(e)}"
            )
        ]


async def capture_fullscreen(path: str):
    """Capture fullscreen screenshot."""
    process = await asyncio.create_subprocess_exec(
        "screencapture", "-x", path,
        stdout=asyncio.subprocess.PIPE,
        stderr=asyncio.subprocess.PIPE
    )
    await process.communicate()
    if process.returncode != 0:
        raise RuntimeError("Failed to capture fullscreen")


async def capture_app_window(app_name: str, path: str):
    """Capture screenshot of specific app window."""
    script = f'tell app "System Events" to get the id of the first window of process "{app_name}"'
    
    # Get window ID
    process = await asyncio.create_subprocess_exec(
        "osascript", "-e", script,
        stdout=asyncio.subprocess.PIPE,
        stderr=asyncio.subprocess.PIPE
    )
    stdout, stderr = await process.communicate()
    
    if process.returncode != 0:
        raise RuntimeError(f"Could not find window for app '{app_name}'")
    
    win_id = stdout.decode().strip()
    
    # Capture window
    process = await asyncio.create_subprocess_exec(
        "screencapture", "-x", f"-l{win_id}", path,
        stdout=asyncio.subprocess.PIPE,
        stderr=asyncio.subprocess.PIPE
    )
    await process.communicate()
    
    if process.returncode != 0:
        raise RuntimeError(f"Failed to capture window for app '{app_name}'")


async def capture_window_by_title(title: str, path: str):
    """Capture screenshot of window by title."""
    try:
        import Quartz
        
        # Get window list
        window_list = Quartz.CGWindowListCopyWindowInfo(
            Quartz.kCGWindowListOptionOnScreenOnly, 
            Quartz.kCGNullWindowID
        )
        
        # Find matching window
        match = None
        for window in window_list:
            window_name = window.get('kCGWindowName', '')
            if title.lower() in str(window_name).lower():
                match = window
                break
        
        if not match:
            raise RuntimeError(f"No window found with title matching '{title}'")
        
        window_id = match['kCGWindowNumber']
        
        # Capture window
        process = await asyncio.create_subprocess_exec(
            "screencapture", "-x", f"-l{window_id}", path,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE
        )
        await process.communicate()
        
        if process.returncode != 0:
            raise RuntimeError(f"Failed to capture window with title '{title}'")
            
    except ImportError:
        raise RuntimeError("Quartz framework not available")
    except Exception as e:
        raise RuntimeError(f"Error capturing window by title: {str(e)}")


async def capture_display(display_num: str, path: str):
    """Capture screenshot of specific display."""
    process = await asyncio.create_subprocess_exec(
        "screencapture", "-x", f"-D{display_num}", path,
        stdout=asyncio.subprocess.PIPE,
        stderr=asyncio.subprocess.PIPE
    )
    await process.communicate()
    
    if process.returncode != 0:
        raise RuntimeError(f"Failed to capture display {display_num}")


async def copy_to_clipboard(path: str):
    """Copy image to clipboard."""
    script = f'set the clipboard to (read (POSIX file "{path}") as JPEG picture)'
    process = await asyncio.create_subprocess_exec(
        "osascript", "-e", script,
        stdout=asyncio.subprocess.PIPE,
        stderr=asyncio.subprocess.PIPE
    )
    await process.communicate()


async def cleanup_file(path: str, delay: int):
    """Clean up temporary file after delay."""
    await asyncio.sleep(delay)
    try:
        import os
        os.remove(path)
    except FileNotFoundError:
        pass  # File already removed


async def main():
    """Main entry point for the MCP server."""
    async with mcp.server.stdio.stdio_server() as (read_stream, write_stream):
        await server.run(
            read_stream,
            write_stream,
            InitializationOptions(
                server_name="screenshot-server",
                server_version="1.0.0",
                capabilities=server.get_capabilities(
                    notification_options=NotificationOptions(),
                    experimental_capabilities={},
                ),
            ),
        )


if __name__ == "__main__":
    asyncio.run(main())
