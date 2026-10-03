# SwiftBonjour

Using NetService (*Bonjour*) to enable network discovery in your app.

This is a maintained derivative fork of [Ciao](https://github.com/AlTavares/Ciao).


## What's Bonjour?

Bonjour, also known as zero-configuration networking, enables automatic discovery of devices and services on a local network using industry standard IP protocols. Bonjour makes it easy to discover, publish, and resolve network services with a sophisticated, easy-to-use programming interface that is accessible from Cocoa, Ruby, Python, and other languages. [Bonjour - Apple Developer](https://developer.apple.com/bonjour/)


## Example

![Example 1](./Example/Screenshots/example_1.png)


## Real-World Demo

![Demo 1](./Example/Screenshots/demo_1.jpg)


## Requirements

- Swift 6.2 or later (the package builds in the Swift 6 language mode)
- iOS 15, tvOS 15, visionOS 1, or macOS 12 or later
- Linux, using [Bouke/NetService](https://github.com/Bouke/NetService) with Avahi's `libavahi-compat-libdnssd-dev`. On Linux, `BonjourServer` needs a port greater than 0, because `.listenForConnections` is not supported there.

watchOS has no `NetService`, so the library is empty on watchOS.


## Usage

### Swift Package Manager

To use SwiftBonjour as a [Swift Package Manager](https://swift.org/package-manager/) package just add the following in your Package.swift file.

``` swift
dependencies: [
    .package(url: "https://github.com/Lessica/SwiftBonjour.git")
]
```


## Other Libraries

- [GCDWebServer](https://github.com/swisspol/GCDWebServer)


## License

SwiftBonjour is released under the MIT license. See [LICENSE](https://github.com/Lessica/SwiftBonjour/blob/main/LICENSE) for details.

