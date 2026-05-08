## Getting Started

Halo teman - teman semua, berikut tutorial untuk menjalakan aplikasi swiftnyaaa :D

## Install Software Update
Teman teman bisa update OS nya dulu yeaah (kalo ada)!

## Menjalankan aplikasi
- Clone terlebih dahulu github repository <br/>
``git clone https://github.com/Quack-Fight/QuackFight.git`
- Buka folder project <br/>
``cd kecedo``
- Selamat mengerjakan!!

## Penggunaan Nama Branch
Untuk nama branch harus menggunakan standar seperti berikut :
- ``(nama)-(tipe): (deskripsi)``

contoh : ``nathan-feat/AimingState``

Setiap membuat fitur baru atau memperbaiki fitur harus menggunakan branch baru seperti SOP diatas dan melakukan pull request yaa

## Cara Commit / Push ke Github untuk Update Progresan
```c
- git add .
- git commit -m "feat: adding AimingState"
- git push origin nathan-feat/AimingState
```
Harus menggunakan [`conventional commits`](https://gist.github.com/qoomon/5dfcdf8eec66a051ecd85625518cfd13)! <br/>
dengan format ``tipe: deskripsi``

<h3>Berikut Tipenya</h3>

- API or UI relevant changes
    - `feat` Commits, that add or remove a new feature to the API or UI
    - `fix` Commits, that fix an API or UI bug of a preceded `feat` commit
- `refactor` Commits, that rewrite/restructure your code, however do not change any API or UI behaviour
    - `perf` Commits are special `refactor` commits, that improve performance
- `style` Commits, that do not affect the meaning (white-space, formatting, missing semi-colons, etc)
- `test` Commits, that add missing tests or correcting existing tests
- `docs` Commits, that affect documentation only
- `build` Commits, that affect build components like build tools, dependencies, project version, ci pipelines, ...
- `ops` Commits, that affect operational components like infrastructure, deployment, backup, recovery, ...
- `chore` Miscellaneous commits e.g. modifying `.gitignore`

## Cara Pull / Mengambil Data Terbaru dari Github ke Lokal
```c
- git pull
- git pull origin (branch) // untuk pull dari branch lain
```
