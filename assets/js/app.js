// Brunch automatically concatenates all files in your
// watched paths. Those paths can be configured at
// config.paths.watched in "brunch-config.js".
//
// However, those files will only be executed if
// explicitly imported. The only exception are files
// in vendor, which are never wrapped in imports and
// therefore are always executed.

// Import dependencies
//
// If you no longer want to use a dependency, remember
// to also remove its path from "config.paths.watched".
import "phoenix_html"

// Import local files
//
// Local files can be imported directly using relative
// paths "./socket" or full ones "web/static/js/socket".

import socket from "./socket"

// import {Socket, Presence} from "phoenix"
//
// let socket = new Socket("/socket", {params: {token: window.token}})
//
// socket.connect()
//
// let userList = document.getElementById("user-list")
// let room = socket.channel("user:wKnVfBOGOWYUCBG9Bmon3ey8Kcn1", {})
// let presences = {}
//
// listBy(id, {metas: [first, ...rest]}) => {
//     first.name = id
//     first.count = rest.length + 1
//     return first
// }
//
// let render = (presences) => {
//   userList.innerHTML = Presence.list(presences, listBy)
//     .map(user => '<li>${user.display_name} (${user.count})')
//     .join("")
// }
//
// room.on("presence_state", state => {
//   Presence.syncState(presences, state)
//   console.log("ayyy")
//   console.log(presences)
//   render(presences)
// })
//
// room.on("presence_diff", diff => {
//   Presence.syncDiff(presences, diff)
//   render(presences)
// })
//
// room.join()
