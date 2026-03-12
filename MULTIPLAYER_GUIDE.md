# Multiplayer guide: demo, workflow, and why RPCs matter

Three short sections: how to run a demo, how netcode flows, and why RPCs are important.

---

## 1. How to get the demo working

### What you need

- Two running copies of the game (so one can host, one can join).
- The main scene includes the multiplayer menu (see below). If it doesn’t, add a `CanvasLayer` and put `multiplayer_menu.tscn` inside it.

### Steps (same project, two windows)

1. **First window (Host)**  
   - Press **Run (F5)**.  
   - You should see: Host, Join, Leave, Offline, IP, Port, status.  
   - Click **Host Game**.  
   - Status should say something like “Server started. Waiting for players…”.  
   - Leave this window running.

2. **Second window (Client)**  
   - Run the project again (e.g. **Run** again, or run an exported build, or a second editor run).  
   - In the new window, click **Join Game**.  
   - Leave IP as `127.0.0.1` (localhost) and port `8080` unless you changed them.  
   - Status should say “Connected to server.”  
   - In the **first** window, the host should see a line in the output like “Peer connected: 2”.

3. **Try an RPC (optional)**  
   - From any script that runs in the client (e.g. a button or `_process`), call:  
     `NetworkManager.send_message_to_server.rpc("Hello")`  
   - On the **host** window, check the **Output** panel: you should see “Player 2 says: Hello”.

4. **Stop**  
   - Click **Leave Game** in either window when done.

### If the menu doesn’t appear when you run

Your main scene must show the menu. Either:

- **Option A:** Set the main scene to a scene that has a `CanvasLayer` with `multiplayer_menu.tscn` instanced inside it, or  
- **Option B:** Open **Project → Project Settings → Application → Run**, set **Main Scene** to `multiplayer_menu.tscn` temporarily so Run launches the menu.

Once the menu is on screen, the steps above are the same.

---

## 2. General workflow with netcode

A simple mental model:

- **Server (host)** = one machine that “owns” the truth (who’s in the game, world state, who did what).
- **Clients** = everyone else; they send inputs and requests, and display what the server (and sync) tell them.

Rough flow:

1. **Start**
   - One instance runs `NetworkManager.host_game(port)` → becomes server.
   - Others run `NetworkManager.join_game(ip, port)` → become clients.
   - Godot connects them and assigns a unique ID to each (1 = server, 2, 3, … = clients).

2. **During play**
   - **Client:** “I pressed Jump” → send that to the server (e.g. via RPC like `request_jump.rpc()`).
   - **Server:** receives the RPC, checks it’s valid, then runs the real game logic (e.g. apply jump). Server is the **authority** for world and rules.
   - **Server → clients:** share the result (e.g. with `MultiplayerSynchronizer` for position/health, or more RPCs). Clients then draw the updated state.

3. **Authority**
   - Each node has a “multiplayer authority” (usually the server, or the client that owns that character).  
   - Only the authority should change that node’s important state (e.g. movement, health).  
   - In your code you do: `if multiplayer.is_multiplayer_authority(): do_the_thing()`.  
   - That way the server (or owning client) decides what happens; others just display it.

4. **Offline**
   - For single-player you call `NetworkManager.start_offline()`.  
   - There is no real network; the local instance is authority for everything.  
   - The same `is_multiplayer_authority()` checks still run and are true where you need them, so one code path works both online and offline.

So the workflow is: **client sends intent (often via RPC) → server (authority) runs and validates logic → server (and sync) update state → everyone sees the same game.**

---

## 3. Why RPC is important

### What an RPC is

- **RPC = Remote Procedure Call.**  
- You mark a function with `@rpc` in GDScript.  
- When someone calls that function **with `.rpc()`**, Godot doesn’t just run it on their machine—it **sends a message** so the function runs on **another** machine (or on all peers, depending on the mode).

So: **RPC is how you “run a piece of your code on someone else’s game instance.”**

### Why that matters

- **The server must run the real game logic.**  
  If only the client moved the character, cheaters could move however they want and the server would believe it. So:
  - Client says: “I want to jump” (e.g. `request_jump.rpc()`).
  - That RPC runs **on the server**. The server then runs the jump logic and updates the character. The server is the authority.
- **You need to trigger logic in the other peer.**  
  Chat, “player X hit player Y”, spawning, voting, etc., all need something to happen on the server or on other clients. RPCs are the way you invoke that logic remotely instead of only locally.

### Modes you’ll use

- **`@rpc("any_peer")`**  
  Any peer (client or server) can call this. Often used so clients can call the server (e.g. “I pressed attack”). The server checks `multiplayer.get_remote_sender_id()` to see who called.
- **`@rpc("any_peer", "call_local")`**  
  Same, but the caller also runs the function locally. Good for things everyone must see (e.g. broadcast chat), including the host.
- **`@rpc("authority")`**  
  Only the authority of the node can call it; others are ignored. Used when only the server (or owner) should trigger something.

### Small example (idea, not full code)

```gdscript
# On the server, this runs when a client calls request_jump.rpc()
@rpc("any_peer")
func request_jump():
    if not multiplayer.is_server():
        return
    var who = multiplayer.get_remote_sender_id()
    # Now run real jump logic for player 'who' (e.g. get their character node and apply velocity)
    apply_jump_for_player(who)
```

So in short: **RPC is how the client tells the server “do this,” and how the server (or others) run code on other machines. That’s why it’s central to netcode.**

---

## Quick reference

| Goal                    | Call / check |
|-------------------------|--------------|
| Host a game             | `NetworkManager.host_game(8080)` |
| Join a game             | `NetworkManager.join_game("127.0.0.1", 8080)` |
| Single-player (no net)  | `NetworkManager.start_offline()` |
| “Only authority runs this” | `if multiplayer.is_multiplayer_authority(): ...` |
| Client asks server to do X | Define `@rpc("any_peer") func do_x(): ...` then call `do_x.rpc()` from client |
| Run on everyone (incl. host) | `@rpc("any_peer", "call_local")` and call with `.rpc()` |

If you want, next step can be a minimal “press a key and see an RPC on the other window” script you can attach to the main scene.
