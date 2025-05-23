# Screenshot MCP Server Setup for Cursor

This directory contains a Model Context Protocol (MCP) server that provides screenshot capabilities to AI assistants like Cursor.

## What is MCP?

MCP (Model Context Protocol) is a standardized way for AI applications to connect to external tools and data sources. Your screenshot server implements this protocol, allowing Cursor to take screenshots through a secure, standardized interface.

## Setup Instructions

### 1. Dependencies (Already Done)
- Virtual environment created: `venv/`
- Dependencies installed via `requirements.txt`

### 2. Test the Server
```bash
# Activate virtual environment
source venv/bin/activate

# Test the server
python test_mcp_server.py
```

### 3. Configure Cursor

To use this MCP server with Cursor, you need to add it to Cursor's MCP configuration:

#### Option A: Using Cursor's Settings
1. Open Cursor
2. Go to Settings → Features → Model Context Protocol
3. Add a new server with these settings:
   - **Name**: `screenshot`
   - **Command**: `python`
   - **Args**: `["screenshotMCP.py"]`
   - **Working Directory**: `/Volumes/FlashGordon/Dropbox/code/chromeless`
   - **Environment**: `PATH=/Volumes/FlashGordon/Dropbox/code/chromeless/venv/bin:/usr/bin:/bin`

#### Option B: Using Configuration File
1. Locate Cursor's configuration directory:
   - macOS: `~/Library/Application Support/Cursor/User/`
2. Create or edit the MCP configuration file
3. Use the provided `cursor-mcp-config.json` as a template

### 4. Available Tools

Once configured, Cursor will have access to the `take_screenshot` tool with these modes:

- **full**: Capture entire screen
- **app**: Capture specific application window (requires app name)
- **window**: Capture window by title (requires window title)
- **display**: Capture specific display (requires display number)

### 5. Usage Examples

Once configured in Cursor, you can ask:
- "Take a screenshot of my entire screen"
- "Capture a screenshot of the Safari app"
- "Take a screenshot of the window titled 'Terminal'"
- "Capture display 2"

## Files in this Setup

- `screenshotMCP.py` - The main MCP server
- `test_mcp_server.py` - Test script to verify the server works
- `requirements.txt` - Python dependencies
- `run_screenshot_server.sh` - Helper script to run with virtual environment
- `cursor-mcp-config.json` - Example Cursor configuration
- `venv/` - Virtual environment (not committed to git)

## Troubleshooting

### Server won't start
- Make sure virtual environment is activated: `source venv/bin/activate`
- Check dependencies are installed: `pip list | grep mcp`

### Cursor can't connect
- Verify the working directory path in configuration
- Check that the virtual environment path is correct
- Test the server manually: `python test_mcp_server.py`

### Screenshots fail
- Ensure you have screen recording permissions on macOS
- Check that the target app/window exists
- Verify display numbers are valid

## Security Notes

- The server only runs locally and doesn't expose network ports
- Screenshots are temporarily saved to `/tmp/` and auto-deleted after 60 seconds
- Images are automatically copied to clipboard for convenience 