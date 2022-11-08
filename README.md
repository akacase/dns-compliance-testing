# dns-compliance-testing

```sh
# to build
nix build github:akacase/dns-compliance-testing

# to view source on latest pin, accessible via `./src` path
nix develop github:akacase/dns-compliance-testing
```

## complications
* doesn't work on macOS ARM, as musl is now a requirement per glib 2.34+ dropping `resolv.h` 

