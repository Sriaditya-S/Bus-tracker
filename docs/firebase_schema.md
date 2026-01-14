# Firebase Realtime Database Schema (MVP)

```
/buses/{busId}/live
  lat: number
  lng: number
  speed: number
  heading: number
  updatedAt: timestamp (server)
  tripId: string
  isActive: boolean

/trips/{tripId}
  meta
    busId: string
    routeId: string
    startAt: timestamp
    endAt: timestamp | null
  points
    {pointId}
      lat: number
      lng: number
      speed: number
      heading: number
      timestamp: timestamp

/routes/{routeId}
  parentsAllowed
    {parentUid}: true
  busId: string
```

Notes:
- `/buses/{busId}/live` is updated every 5–10 seconds while moving.
- `points` stores the trail for playback or analytics.
- `routes/{routeId}/parentsAllowed` lists which parents can read a route.
