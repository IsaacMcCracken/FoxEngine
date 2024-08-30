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

    if fox.is_key_pressed(.SPACE) do fmt.println("Fart Smeller")

    if fox.is_key_down(.LEFT_CONTROL) && fox.is_key_down(.LEFT_SHIFT) && fox.is_key_pressed(.H) {
      fmt.println("Hot Reloading Goes here")
    }

    fox.app_poll()

    // change api
    if fox.begin_drawing() {
      // fmt.println("got gere")

      fox.end_drawing()
    }

  }

}