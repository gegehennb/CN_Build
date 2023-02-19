name: Build caddy

on:
  workflow_dispatch:

  release:
    types: 
      - 'prereleased' 
      - 'published' 
      - 'released'

jobs:
  build:
    runs-on: ubuntu-latest
    strategy:
      fail-fast: false
      matrix:
        config:
        - {
            name: "linux-amd64",
            GOARCH: amd64,
            GOOS: linux,
            release: true
          }
        - {
            name: "linux-arm64",
            GOARCH: arm64,
            GOOS: linux,
            release: true
          }

    steps:
    - name: Checkout
      uses: actions/checkout@v3

    - name: Install go
      uses: actions/setup-go@v3
      with:
        go-version: '1.20'
        check-latest: true
    
    - name: Install xcaddy
      run: go install github.com/caddyserver/xcaddy/cmd/xcaddy@latest
    
    - name: Build caddy
      run: |
        mkdir release-tmp
        export GOARCH=${{ matrix.config.GOARCH }} 
        export GOOS=${{ matrix.config.GOOS }} 
        ~/go/bin/xcaddy build \
          --with github.com/caddyserver/forwardproxy@caddy2=github.com/klzgrad/forwardproxy@naive \
          --output ./release-tmp/caddy
        
    - name: Generate tar for Linux
      run: |
        mkdir release-ready
        cd ./release-tmp
        tar -zcvf ../release-ready/caddy-${{ matrix.config.name }}.tar.gz *

    - name: Upload a Build Artifact
      uses: actions/upload-artifact@v3
      with:
        name: caddy-${{ github.sha }}-${{ matrix.config.name }}
        path: ./release-ready/*
        
    - name: Upload to GitHub Release for Linux
      uses: svenstaro/upload-release-action@v2
      with:
        repo_token: ${{ secrets.ACCESS_TOKEN }}
        file: ./release-ready/caddy-${{ matrix.config.name }}.tar.gz
        tag: ${{ github.ref }}
        overwrite: true
