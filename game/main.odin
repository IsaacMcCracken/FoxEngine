package game

import "core:fmt"
import "core:log"
import "core:os/os2"
import "core:os"

import vmem "core:mem/virtual"

import "vendor:wgpu"


import "../fox"


main :: proc() {
  

  fmt.println("Hellope")

  fox.app_init(800, 800, "Sexy Game")
  defer fox.app_deinit()

  
  for fox.app_running() {
    fox.app_poll()

    // change api
    if fox.begin_drawing() {
      // fmt.println("got gere")

      fox.end_drawing()
    }

  }

}