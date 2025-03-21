{
  "targets": [
    {
      "target_name": "command_key_listener",
      "cflags!": [ "-fno-exceptions" ],
      "cflags_cc!": [ "-fno-exceptions" ],
      "sources": [ "command_key_listener.mm" ],
      "include_dirs": [
        "<!@(node -p \"require('node-addon-api').include\")"
      ],
      "defines": [ "NAPI_DISABLE_CPP_EXCEPTIONS" ],
      "conditions": [
        [
          "OS==\"mac\"",
          {
            "xcode_settings": {
              "GCC_ENABLE_CPP_EXCEPTIONS": "YES",
              "CLANG_CXX_LIBRARY": "libc++",
              "MACOSX_DEPLOYMENT_TARGET": "10.15",
              "OTHER_CFLAGS": [ "-std=c++14", "-stdlib=libc++" ]
            },
            "link_settings": {
              "libraries": [
                "-framework CoreFoundation",
                "-framework Cocoa",
                "-framework Carbon"
              ]
            }
          }
        ]
      ]
    }
  ]
} 