size:
    @sn d target/all.min.js

script:
    @mkdir -p .shake
    @cp shake.hs .shake
    cd .shake && ghc -O2 shake.hs -o build
    @mv .shake/build .

view: build
    firefox-trunk target/index.html
