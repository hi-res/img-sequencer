# img-sequencer

Image sequence and spritesheet utility for the web.

## Setup

This will install the required node modules and image utlities required to run the exporting scripts.

```
make setup
```

## Examples

```
make test-server
```

And open [localhost:8080/examples](http://localhost:8080/examples)



## FAQ

If some errors occur like this:

```
montage: unable to read font `/usr/local/share/ghostscript/fonts/n019003l.pfb'
```

you have to install ghostscript.
If you are using Homebrew you can install it via

```
brew install ghostscript
```


Reference : http://stackoverflow.com/questions/13936256/imagemagick-error-while-running-convert-convert-unable-to-read-font