# ./configure

**A semi-universal `./configure` script.**

This script can configure your `Makefile`
and then help your Makefile configure other sources.

### Usage as a project `./configure` script

Inside the `./configure` script:

```bash
variables['INSTALL_PATH']="${HOME}/bin"
variables['INTERPRETER']="python3.4"
variables['VERSION']='0.10.33'
```

Before invoking `make && sudo make install`:

```bash
./configure --install-path=/usr/bin --interpreter=python3.5
```

The `./configure` script also prints some nice `--help` messages
based on the `variables` array and other custom configuration.

### Usage from a Makefile:

```make
gh-pages.sh: src/gh-pages.sh
    ./configure \
        --silent \
        --variable-VERSION="$(VERSION)" \
        --preprocessor-suffix=' # <<< configure' \
        --in-file="$<" \
        --out-file="$@"
    chmod a+x gh-pages.sh
```

Input `src/gh-pages.sh`:

```bash
VERSION=0.0.0 # <<< configure
```

Output `./gh-pages.sh`:

```bash
VERSION=0.10.33 # <<< configure
```
