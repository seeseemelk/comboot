# comboot
A tool for booting old x86 PCs from serial

## Building
### Bootloader
The bootloader image is build using NASM and Make
Build the image by running
```sh
$ make
```
The generated floppy image is stored in `bin/asm/comboot.img`.

### Server
The server is build using Gradle and Java.
A runnable jar cannot yet be built, but the server
can be started by running:
```sh
$ ./gradlew run
```

## Testing
The bootloader can be tested with Qemu.
The first serial port should be configured to be accessible via TCP.
The simplest way to run it is to simply run:
```sh
$ make emulate
```
Next, start the server:
```sh
$ ./gradlew run
```
