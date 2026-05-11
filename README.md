## Getting Started

Halo teman - teman semua, berikut tutorial untuk menjalakan aplikasi swiftnyaaa :D

## Install Software Update
Teman teman bisa update OS nya dulu yeaah (kalo ada)!

## Menjalankan aplikasi
- Clone terlebih dahulu github repository <br/>
```c
git clone https://github.com/Quack-Fight/QuackFight.git
```
- Buka folder project <br/>
```c
cd QuackFight
```
- Selamat mengerjakan!!

## Development Flow
1. Jangan lupa untuk selalu rely dan update [Github Projects](https://github.com/orgs/Quack-Fight/projects/2)
2. Di github project, pilih draft issue yang ingin dikerjakan, lalu bisa diklik titlenya
    <img width="1512" height="892" alt="image" src="https://github.com/user-attachments/assets/8ffb9890-d3ca-4277-a31a-16eb82a3512d" />
3. Di bagian kanan bawah, terdapat tombol convert to issue, jangan lupa untuk membuat memilih repo QuackFight
    <img width="384" height="426" alt="image" src="https://github.com/user-attachments/assets/0b3bc420-454f-44b7-aefc-95fefa027d92" />
4. Setelah issue berhasil tercreate, maka kita bisa memulai development phase dengan membuat branch dari issue tersebut, dengan klik "Create a branch" di bagian "Development" di kanan bawah issue tersebut.
    <img width="1512" height="897" alt="image" src="https://github.com/user-attachments/assets/970b95c3-9683-4805-8142-e9915f097d2c" />
5. Pastikan untuk tidak mengubah nama branch untuk menjaga konsistensi <br>
6. Selanjutnya, kalian bisa melakukan `git checkout <nama-branch>` untuk memulai development di branch tersebut <br>
7. Happy Working! <br>
8. Jika sudah selesai development di issue tersebut, maka bisa melakukan Pull Request dengan source branch adalah branch di issue tersebut, dan target branch adalah ke `staging` <br>
9. Jika review sudah aman, pastikan merging ke branch staging menggunakan "Squash and Merge" untuk menjaga history repository clean and makes it easier to track or revert changes

## Cara Commit / Push ke Github untuk Update Progresan
```
git add .
git commit -m "feat: adding AimingState"
git push origin <nama-branch>
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
git pull
git pull origin (branch) // untuk pull dari branch lain
```

## Cara rebase branch dari target branch
```c
git pull --rebase origin <nama-branch>
git push --force-with-lease
```
- Pastikan untuk meresolve semua conflict thoughtfully jika ada.
