https://github.com/Coldcard/firmware

# Quick-start guide

1. Build the image (one-time, ~10–15 min due to submodule compilation):

```bash
docker compose build
```

2. Allow the container to connect to your host display (Linux):

```bash
xhost +local:docker
```

3. Run the simulator:

```bash
docker compose up
```

4. Place files on the simulated MicroSD by copying them into the named volume's MicroSD/ subdirectory, or by using a bind-mount override in a docker-compose.override.yml.


# Key design decisions

- Ubuntu 22.04 base:	Explicitly supported by the README; avoids needing ubuntu24_mpy.patch
- pysdl2-dll pip package	Provides the SDL2 runtime library in Python without relying solely on the system libsdl2
- VOLUME for unix/work	Persists simulated MicroSD, virtual disk, and wallet settings across container restarts
- ENTRYPOINT + empty CMD	Allows passing extra simulator.py flags via docker compose run coldcard-simulator --flag
- restart: "no"	The simulator is interactive; it should not auto-restart on exit
