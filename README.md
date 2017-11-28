# ProjectMeetings

[![Run in Postman](https://run.pstmn.io/button.svg)](https://app.getpostman.com/run-collection/afabcdfcbed7b5b12eff)

Too often, meetings go on for too long and accomplish far too little. There are usually a few people who do all the talking while everyone else is either unable to speak, distracted, or uninterested. Although there are many “meeting” apps on the marketplace (such as WebEx or GoToMeeting), none of them truly solve this problem. These apps are more concerned with facilitating meetings which couldn’t exist otherwise than actually laying a foundation for engaging and productive meetings. Because of this, we’re creating an app that reworks the common meeting by laying a foundation for structure within a meeting and giving everyone the ability to contribute in an essential way; we believe this will improve engagement and productivity across the board, helping meetings accomplish more in a fraction of the time.

# Table of Contents

- [Elixir / Phoenix Documentation](#elixir-/-phoenix-documentation)
- [API Documentation](#api-documentation)
- [WebSockets Documentation](#websockets-documentation)

## Elixir / Phoenix Documentation

Elixir website: https://elixir-lang.org/

To start your Phoenix server:

  * Install dependencies with `mix deps.get`
  * Install Node.js dependencies with `cd assets && npm install`
  * Start Phoenix endpoint with `mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

You can learn more at: http://www.phoenixframework.org/

## API Documentation

API Domain: http://ec2-34-226-155-228.compute-1.amazonaws.com:8080

API Endpoints:

- `/api/user`
  - PUT `/`
  - GET `/email/:email`
  - GET `/uid/:u_id`
  - DELETE `/invites/:m_id`

- `/api/meeting`
  - POST `/`
  - GET `/:m_id`
  - PUT `/:m_id`
  - DELETE `/:m_id`
  - POST `/:m_id/invites`
  - DELETE `/:m_id/invites`

### /api/user
#### PUT /
Will create/update a user object in Firebase and is called after the user has signed in with Google Oauth2. Requires the Firebase uid, email, display name, and Firebase id token provided by a Firebase user object after creating an account. In addition, this method requires a Google id token, provided by a Google account object after signing in with Google. If updating a user's information, you may choose to provide some, but not all, of the required information, assuming that you provide a valid token.

Example body:
```
{
	"display_name": "Two Names",
	"email": "twonames@gmail.com",
	"google_token": "eyJhbGciOiJSUzI1NiIsImtpZCI6ImNiMTFlMmYyMzNhZWUwMzI5YTUzNDQ1NzAzNDljZGRiNmI4ZmYyNTIifQ.eyJhenAiOiI3MTE3NDI3MDQ1ODEtbGxlcmQ2NnZoM3U0MHBlYm40OWFrNGdnZ2Q3aGJvMDUuYXBwcy5nb29nbGV1c2VyY29udGVudC5jb20iLCJhdWQiOiI3MTE3NDI3MDQ1ODEtZzlzNTZnaWJjYXEyNjU4MjVnOGFoNXE0NWQ2YnVxMWwuYXBwcy5nb29nbGV1c2VyY29udGVudC5jb20iLCJzdWIiOiIxMTQ5MjA4ODY4MTYyNDAwMjEyOTEiLCJlbWFpbCI6ImNhbGViLnNvbG9yaW9AZ21haWwuY29tIiwiZW1haWxfdmVyaWZpZWQiOnRydWUsImlzcyI6Imh0dHBzOi8vYWNjb3VudHMuZ29vZ2xlLmNvbSIsImlhdCI6MTUwOTg1NjEyNSwiZXhwIjoxNTA5ODU5NzI1LCJuYW1lIjoiQ2FsZWIgU29sb3JpbyIsInBpY3R1cmUiOiJodHRwczovL2xoNS5nb29nbGV1c2VyY29udGVudC5jb20vLWQyNjhqLUJnaTZJL0FBQUFBQUFBQUFJL0FBQUFBQUFBQUFBL0FOUTBrZjdFdmM4QkV3U2k0dWtqVW5wd1VXWEg1bkYyaVEvczk2LWMvcGhvdG8uanBnIiwiZ2l2ZW5fbmFtZSI6IkNhbGViIiwiZmFtaWx5X25hbWUiOiJTb2xvcmlvIiwibG9jYWxlIjoiZW4ifQ.FecOT2hEr15qWJZ9snWwyxboiFgBb6xD2yfvdHeAnH-ZA_ZmegAKCzN1r1kfBxzk-EpIuyQW3Z6Mouz_tNku60_PMWBj51JYcyRh2w6PsBojvxeriibUlz7HvRIiP-jqssPrw3v2gpBqlmPoza-sfeQeSzBQ_OOAAbSJqVylrxxVRG_ikWz8AsdGF-ht61sjcEktLnOpKZ-7nM-vJ6nqGLQCkam2nWcaNCFNVfXRGQ6dScQre3iuGKJmXypjnnS8g8QVjMpdmDIaFWLM_3GnrvjRkftOfW7qYnpNr8RsZIx5LK5nD_zK052iq0v61yZ5zj5emM_KIN-0nxHNK85JBg",
	"firebase_token": "eyJhbGciOiJSUzI1NiIsImtpZCI6IjljMzgwZDMxODdjNDZhM2RkNzA4ZDhkNjNjN2E0ODMxZjg3MzFlM2QifQ.eyJpc3MiOiJodHRwczovL3NlY3VyZXRva2VuLmdvb2dsZS5jb20vcHJvamVjdG1lZXRpbmctMTgzNzA2IiwibmFtZSI6IkNhbGViIFNvbG9yaW8iLCJwaWN0dXJlIjoiaHR0cHM6Ly9saDUuZ29vZ2xldXNlcmNvbnRlbnQuY29tLy1kMjY4ai1CZ2k2SS9BQUFBQUFBQUFBSS9BQUFBQUFBQUFBQS9BTlEwa2Y3RXZjOEJFd1NpNHVralVucHdVV1hINW5GMmlRL3M5Ni1jL3Bob3RvLmpwZyIsImF1ZCI6InByb2plY3RtZWV0aW5nLTE4MzcwNiIsImF1dGhfdGltZSI6MTUwOTg1Nzg5OCwidXNlcl9pZCI6IjBvSzI1c1V4YnRhSWIwdWw5dzVOYXptZUxxaTEiLCJzdWIiOiIwb0syNXNVeGJ0YUliMHVsOXc1TmF6bWVMcWkxIiwiaWF0IjoxNTA5ODU3ODk5LCJleHAiOjE1MDk4NjE0OTksImVtYWlsIjoiY2FsZWIuc29sb3Jpb0BnbWFpbC5jb20iLCJlbWFpbF92ZXJpZmllZCI6dHJ1ZSwiZmlyZWJhc2UiOnsiaWRlbnRpdGllcyI6eyJnb29nbGUuY29tIjpbIjExNDkyMDg4NjgxNjI0MDAyMTI5MSJdLCJlbWFpbCI6WyJjYWxlYi5zb2xvcmlvQGdtYWlsLmNvbSJdfSwic2lnbl9pbl9wcm92aWRlciI6Imdvb2dsZS5jb20ifX0.eSrriX8ccU9vrFePR6PRil3HGX69xD6SWX6PHhqi-BnONUaKHG8uCUW7OypqGaRXB8DK-VisbQ-PgAWxKuVY9bdQs02mLPfz0JgBOfGK-UqrBjXNAHTApmCa1Lb2wodU8p6A5KrNXnCFRYtedoBW3tMBFiCxwE7YqbflVKnPH4AIUj4MTEUJa52SU0SXnJPmM2mpSF4Wc_6vkd00jww5jBFoT-YTKVD53koAlk60-SJTyJhcUdZgzNfBuaV3gwGkD_F0fX-si8ttPMgoUqs4Zk47UB1FSzXCI3kNvZ1ijG9sAaR5M1MFeY-gtwse-OwzVe9Sa8BmLzYJE9LQ9VIuLQ",
  "instance_id": "eBnCp4Jnsu8:APA91bElIE7wPG_TBJISmMWbKREopRfLyqvqja_WBXSbRqxYZ6Yb6l2cE1FTHxRub05tqEu0zM5bQ7E0rVFH0_baoRjUAQOehN4oJcvEqzRfyDESDmxXGRjzw_YGycR4Sof8pinJdYh4"
}
```

#### GET /email/:email
Retrieves a user's public-facing information by their email. Requires a valid token.

Example request: `/api/email/twonames@gmail.com`

Example Header:

Key | Value
------------ | -------------
token | eyJhbGciOiJSUzI1NiIsImtpZCI6IjljMzgwZDMxODdj...

#### GET /uid/:u_id
Retrieves a user's public-facing information by their Firebase-provided user id. Requires a valid token.

Example request: `/api/uid/0oK25sUxbtaIb0ul9w5NazmeLqi1`

Example Header:

Key | Value
------------ | -------------
token | eyJhbGciOiJSUzI1NiIsImtpZCI6IjljMzgwZDMxODdj...

#### DELETE /invites/:m_id
Rejects an invite to a meeting sent to the user. Requires a valid token.

Example request: `/api/invites/51b46c5c-29e8-4e8e-ac48-226d7fb1fdf3`

Example Header:

Key | Value
------------ | -------------
token | eyJhbGciOiJSUzI1NiIsImtpZCI6IjljMzgwZDMxODdj...

### /api/meeting
#### POST /
Will create a meeting object in Firebase. Requires a name, objective statement, start time (UNIX time), time limit (in ms), and the drive folder id. Invites can also be included. Requires a valid token.

Example Header:

Key | Value
------------ | -------------
token | eyJhbGciOiJSUzI1NiIsImtpZCI6IjljMzgwZDMxODdj...

Example body:
```
{
	"name": "Two Names Meeting",
	"objective": "Learn to call Two Names by his actual name..."
	"time": 1609843492,
	"time_limit": 600000,
	"drive_folder_id": "0B0SCJBL1Pu8eaWwxU1hnMFZrTVU",
	"invites": ["heyguys.letscallhimTwoNamesinsteadofhisactualname@yahoo.com", "soundsgood.lol@aol.com"]
}
```

#### GET /:m_id
Retrieves a meetings facing information if the requestor is either the creator or member of the meeting. Requires a valid token.

Example request: `/api/meetings/51b46c5c-29e8-4e8e-ac48-226d7fb1fdf3`

Example Header:

Key | Value
------------ | -------------
token | eyJhbGciOiJSUzI1NiIsImtpZCI6IjljMzgwZDMxODdj...

#### PUT /:m_id
Retrieves a meetings information if the requestor is either the creator or member of the meeting. Requires a valid token.

Example request: `/api/meetings/51b46c5c-29e8-4e8e-ac48-226d7fb1fdf3`

Example Header:

Key | Value
------------ | -------------
token | eyJhbGciOiJSUzI1NiIsImtpZCI6IjljMzgwZDMxODdj...


Example body:
```
{
	"name": "ANGRY Two Names Meeting",
	"objective": "Learn to call Two Names by his actual name...THROUGH FORCE"
	"time": 1609843492,
	"time_limit": 60000000,
	"drive_folder_id": "0B0SCJBL1Pu8eaWwxU1hnMFZrTVU",
}
```

#### DELETE /:m_id
Deletes a meeting as well as its associated invites if the requestor is the creator of the meeting. Requires a valid token.

Example request: `/api/meetings/51b46c5c-29e8-4e8e-ac48-226d7fb1fdf3`

Example Header:

Key | Value
------------ | -------------
token | eyJhbGciOiJSUzI1NiIsImtpZCI6IjljMzgwZDMxODdj...

#### POST /:m_id/invites
Will create invite(s) to a meeting in Firebase through reference to users' email. Emails must be registered with the app. The requestor must be the creator of the meeting. Requires a valid token.

Example request: `/api/meetings/51b46c5c-29e8-4e8e-ac48-226d7fb1fdf3`

Example Header:

Key | Value
------------ | -------------
token | eyJhbGciOiJSUzI1NiIsImtpZCI6IjljMzgwZDMxODdj...

Example body:
```
{
	"emails": ["heyguys.letscallhimTwoNamesinsteadofhisactualname@yahoo.com", "soundsgood.lol@aol.com", "letscallhimbyhisrealname@gmail.com"]
}
```

#### DELETE /:m_id/invites
Will delete invite(s) to a meeting in Firebase through reference to users' email. The requestor must be the creator of the meeting. Requires a valid token.

Example request: `/api/meetings/51b46c5c-29e8-4e8e-ac48-226d7fb1fdf3`

Example Header:

Key | Value
------------ | -------------
token | eyJhbGciOiJSUzI1NiIsImtpZCI6IjljMzgwZDMxODdj...

Example body:
```
{
	"emails": ["heyguys.letscallhimTwoNamesinsteadofhisactualname@yahoo.com", "soundsgood.lol@aol.com"]
}
```

## WebSocket Documentation

To use websockets, establish a socket connection with the endpoint specified below. Once a connection is established,
the client can join different rooms within the "user" or "meeting" channels (provided their credentials are valid).
The client can send messages to the rooms which will be broadcast to all users in the room (more details found below).

WebSocket Endpoint: ws://ec2-34-226-155-228.compute-1.amazonaws.com:8080/socket/websocket?token=<FIREBASE TOKEN>

#### User Channel
Connect to a certain room with in the user channel by specifying topic as `user:<U_ID>`

Events sent to the room include:
`phx_join`: Will authenticate the user before letting them into the room.

Events sent by the room include:
`presence_state`: Informs newly-joined users of other presences within the room.
`presence_diff`: Informs users of when a change in presences within the room occurs.

#### Meeting Channel
Connect to a certain room with in the meeting channel by specifying topic as `meeting:<M_ID>`

Events sent to the room include:
`phx_join`: Will authenticate the user before letting them into the room.

Events sent by the room include:
`presence_state`: Informs newly-joined users of other presences within the room.
`presence_diff`: Informs users of when a change in presences within the room occurs.
`meeting_start`: Informs users that the meeting has started (must be meeting creator to enact this).
`msg`: Posts a new message in the meeting.
`applause`: Sends new applause to the meeting.
`file_share`: Alerts other users of a new file shared.

## Firebase Security Rules
```
{
  "rules": {
    ".write": false,
    ".read": "auth != null",
    "users": {
      "$uid": {
        "firebase_token": {
        	".read": "$uid === auth.uid"
        },
        "google_token": {
          ".read": "$uid === auth.uid"
        },
        "instance_id": {
        	".read": "$uid === auth.uid"
        },
				"invites": {
          ".read": "$uid === auth.uid"
        },
        "meetings": {
          ".read": "$uid === auth.uid"
        }
      }
    },
    "users_by_email": {
      "$email": {
        "firebase_token": {
        	".read": "auth.uid == data.child('u_id').val()"
        },
        "google_token": {
          ".read": "auth.uid == data.child('u_id').val()"
        },
        "instance_id": {
        	".read": "auth.uid == data.child('u_id').val()"
        },
				"invites": {
          ".read": "auth.uid == data.child('u_id').val()"
        },
        "meetings": {
          ".read": "auth.uid == data.child('u_id').val()"
        }
      }
    },
    "meetings": {
      "$mid": {
        ".read": "root.child('users/' + auth.uid).hasChild('invites/' + $mid) || root.child('users/' + auth.uid).hasChild('meetings/' + $mid)"
      }
    }
  }
}
```
