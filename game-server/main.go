package main

import (
	"encoding/json"
	"fmt"
	"net/http"
	"sync"

	"github.com/gorilla/websocket"
)

var editIDCounter int = 0
var mu sync.Mutex

type Module string

const (
	OnlineModule Module = "OnlineModule"
	EditorModule Module = "EditorModule"
)

type ClientState struct {
	ID   string
	Room string
}

type Update struct {
	Module Module                 `json:"module"`           // module name
	ID     *string                `json:"id,omitempty"`     // user id
	MS     int                    `json:"ms"`               // client time in milliseconds since level started
	Pos    *PositionUpdate        `json:"pos,omitempty"`    // position
	Val    map[string]interface{} `json:"val,omitempty"`    // property values
	Tile   []TileUpdate           `json:"tile,omitempty"`   // tile updates
	Char   *CharacterUpdate       `json:"char,omitempty"`   // character values, stats, look, etc
	Room   *string                `json:"room,omitempty"`   // used to set ClientState.Room, client will then only recieve updates to that room
	Ret    *bool                  `json:"ret,omitempty"`    // if true, return this message to the sender
	Editor *LevelEditorUpdate     `json:"editor,omitempty"` // editor updates for multiplayer level editor
}

type PositionUpdate struct {
	X  int `json:"x"`  // x position
	Y  int `json:"y"`  // y position
	VX int `json:"vx"` // x velocity
	VY int `json:"vy"` // y velocity
}

type TileUpdate struct {
	X     int    `json:"x"`     // tile x
	Y     int    `json:"y"`     // tile y
	Layer int    `json:"layer"` // layer id
	Block string `json:"block"` // block id
}

type CharacterUpdate struct {
	Head int `json:"head"`
	Body int `json:"body"`
	Feet int `json:"feet"`
	Name int `json:"name"`
}

type LevelEditorUpdate struct {
	EditId    int        `json:"edit_id"`
	Type      string     `json:"type"`
	LayerName string     `json:"layer_name"`
	Position  Vector2    `json:"position"`
	UserText  string     `json:"usertext"`
	Font      string     `json:"font"`
	FontSize  int        `json:"font_size"`
	Coords    Vector2i   `json:"coords"`
	BlockID   int        `json:"block_id"`
	Points    []Vector2i `json:"points"`
	Name      string     `json:"name"`
	Rotation  int        `json:"rotation"`
	Depth     int        `json:"depth"`
}

type Vector2 struct {
	X float64 `json:"x"`
	Y float64 `json:"y"`
}

type Vector2i struct {
	X int `json:"x"`
	Y int `json:"y"`
}

var upgrader = websocket.Upgrader{
	ReadBufferSize:  1024,
	WriteBufferSize: 1024,
	CheckOrigin: func(r *http.Request) bool {
		// origin := r.Header.Get("Origin")
		// return origin == "http://127.0.0.1:8081" || origin == "https://platformracing.com" || origin == "https://dev.platformracing.com"
		return true // allow all origins
	},
}

var clients = make(map[*websocket.Conn]*ClientState)
var sendQueue = make(chan Update)

func main() {
	http.HandleFunc("/health", handleHealth)
	http.HandleFunc("/ws", handleWS)

	go handleMessages()

	fmt.Println("PR4 Game Server started on :8081")
	err := http.ListenAndServe(":8081", nil)
	if err != nil {
		panic("Error starting server: " + err.Error())
	}
}

func handleHealth(w http.ResponseWriter, r *http.Request) {
	fmt.Println(w, "ok")
}

func handleWS(w http.ResponseWriter, r *http.Request) {
	conn, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		fmt.Println(err)
		return
	}
	defer conn.Close()

	clients[conn] = &ClientState{}

	for {
		var update Update
		_, message, err := conn.ReadMessage()
		if err != nil {
			fmt.Println("Error reading message:", err)
			delete(clients, conn)
			return
		}

		jsonString := string(message)
		fmt.Println("Received JSON as string:", jsonString)

		err = json.Unmarshal(message, &update)
		if err != nil {
			fmt.Println("Invalid JSON received:", err)
			delete(clients, conn)
			return
		}

		// clientState stores metadata tied to this connection
		clientState := clients[conn]

		// persist room so it does not need to be sent with every request
		if update.Room != nil {
			clientState.Room = *update.Room
		} else {
			update.Room = &clientState.Room
		}

		// perist user id so it does not need to be sent with every request
		// todo: this field should not be set by the client, but fetched from session
		if update.ID != nil {
			clientState.ID = *update.ID
		} else {
			update.ID = &clientState.ID
		}

		if update.Module == EditorModule {
			mu.Lock()
			if update.Editor == nil {
				update.Editor = &LevelEditorUpdate{}
			}
			update.Editor.EditId = editIDCounter
			editIDCounter++
			mu.Unlock()
		}

		// send this update off to be sent
		sendQueue <- update
	}
}

func handleMessages() {
	for {
		update := <-sendQueue

		// skip updates if they do not have a room set
		if update.Room == nil {
			continue
		}

		// skip updates if they do not have a user id set
		if update.ID == nil {
			continue
		}

		// loop through each client
		for client, clientState := range clients {

			// skip this client if it is not in the target room
			if clientState.Room != *update.Room {
				continue
			}

			// do not send an update back to the same client it originated from unless ret=true
			if clientState.ID == *update.ID && !*update.Ret {
				continue
			}

			// write the update to the client
			err := client.WriteJSON(update)
			if err != nil {
				fmt.Println(err)
				client.Close()
				delete(clients, client)
			}
		}
	}
}
