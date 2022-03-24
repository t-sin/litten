# litten - a language system

**This project only run on x86-64 GNU/Linux.**

## Runnin on a Docker container

```
$ docker build -t litten .
$ docker run -it -v $PWD:/app litten /bin/bash
$ cd /app
$ make && ./litten
```

## Author

- Shinichi Tanaka (<shinichi.tanaka45@gmail.com>)

## License

*Litten* is licensed under the GPLv3.
