{
  "targets": [
    {
      "target_name": "active-app",
      "sources": [ "active-app.mm" ],
      "include_dirs": [
        "<!@(node -p \"require('node-addon-api').include\")"
      ],
      "defines": [ "NAPI_DISABLE_CPP_EXCEPTIONS" ],
      "conditions": [
        ['OS=="mac"', {
          "xcode_settings": {
            "MACOSX_DEPLOYMENT_TARGET": "10.13",
            "OTHER_CPLUSPLUSFLAGS": ["-std=c++17", "-stdlib=libc++"],
            "OTHER_LDFLAGS": ["-framework CoreGraphics", "-framework AppKit"]
          }
        }]
      ]
    }
  ]
} 