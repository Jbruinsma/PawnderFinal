# Pawnder App

Flutter frontend for Pawnder.

## Running on a Physical Phone

Do not use `localhost` for the backend when running on a real phone. On a
physical device, `localhost` points to the phone itself, not the computer
running Docker.

1. Make sure the phone and computer are on the same Wi-Fi.
2. Start the backend so `http://localhost:8000/docs` works on the computer.
3. Find the computer's Wi-Fi IP address.

On macOS:

```sh
ipconfig getifaddr en0
```

If that returns nothing, use:

```sh
ifconfig en0 | grep "inet "
```

4. Run Flutter with that IP:

```sh
flutter run --dart-define=API_BASE_URL=http://YOUR_MAC_IP:8000
```

Example:

```sh
flutter run --dart-define=API_BASE_URL=http://192.168.1.42:8000
```

You should also be able to open `http://YOUR_MAC_IP:8000/docs` in Safari on the
phone. If Safari cannot reach it, the app cannot either.
