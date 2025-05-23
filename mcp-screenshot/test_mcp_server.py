#!/usr/bin/env python3

import asyncio
import json
import subprocess
import sys
from mcp import ClientSession, StdioServerParameters
from mcp.client.stdio import stdio_client


async def test_screenshot_server():
    """Test the screenshot MCP server."""
    
    # Server parameters
    server_params = StdioServerParameters(
        command="python",
        args=["screenshotMCP.py"],
        env=None
    )
    
    try:
        # Connect to the server
        async with stdio_client(server_params) as (read_stream, write_stream):
            async with ClientSession(read_stream, write_stream) as session:
                # Initialize the connection
                await session.initialize()
                print("✅ Successfully connected to MCP server")
                
                # List available tools
                tools = await session.list_tools()
                print(f"✅ Available tools: {len(tools.tools)}")
                for tool in tools.tools:
                    print(f"   - {tool.name}: {tool.description}")
                
                # Test taking a full screenshot
                print("\n🔄 Testing full screenshot...")
                result = await session.call_tool(
                    "take_screenshot",
                    arguments={"mode": "full"}
                )
                
                if result.content:
                    print("✅ Screenshot taken successfully!")
                    for content in result.content:
                        if hasattr(content, 'text'):
                            print(f"   Result: {content.text}")
                else:
                    print("❌ No result returned")
                    
    except Exception as e:
        print(f"❌ Error testing server: {e}")
        return False
    
    return True


if __name__ == "__main__":
    print("Testing Screenshot MCP Server...")
    success = asyncio.run(test_screenshot_server())
    if success:
        print("\n✅ All tests passed!")
    else:
        print("\n❌ Tests failed!")
        sys.exit(1) 