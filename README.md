# runpod-h3

MiniMax H3 (видео + звук) на RunPod через [WanGP](https://github.com/deepbeepmeep/Wan2GP): одна команда — установка, запуск, автоперезапуск при падениях, сторож памяти.

Проверено 2026-11-02: RTX 5090, WanGP v19.02, torch 2.10 / cu130.

| Модель (WanGP) | Ролик | Время | Цена на 5090 ($1.19/ч) |
|---|---|---|---|
| H3 FL2VA Pruned 20B · PDD 8-Step | 5 с, 1280×704 | 1 мин 43 с | $0.034 |
| H3 FL2VA 33B · PDD 8-Step | 5 с, 1280×704 | ~1 мин 55 с | ~$0.038 |
| H3 FL2VA 33B · PDD 8-Step | 10 с, 1280×704 | 4 мин 48 с | $0.095 |

## 1. Создать под

- **GPU:** RTX 5090 (лучшая цена за ролик; L40/4090 дороже за ролик).
- **Шаблон:** RunPod PyTorch, фильтр **CUDA 13.x**.
- **Expose HTTP ports:** `8888, 7860`.
- **Хранилище** — один из двух режимов:

| Режим | Что выбрать | Плюс | Минус |
|---|---|---|---|
| **С Network Volume** | Volume ~200 ГБ на `/workspace`, container disk 30 ГБ | следующий запуск ~2 мин | ~$14/мес, volume привязан к дата-центру (там должна быть 5090) |
| **Без volume** | container disk 200 ГБ | $0 в простое | каждый запуск заново: установка + скачивание моделей ~15–20 мин (~$0.3) |

Volume окупается, если запусков больше ~45 в месяц или жалко 15 минут.

## 2. Запуск

В терминале пода (Connect → Web Terminal):

```bash
cd /workspace && git clone <URL этого репозитория> runpod-h3 && bash runpod-h3/start.sh
```

Нет git-репозитория — загрузите `runpod-h3.tar` через Jupyter (порт 8888) в `/workspace`, затем:

```bash
cd /workspace && tar xf runpod-h3.tar && bash runpod-h3/start.sh
```

Скрипт напечатает ссылку `https://<POD_ID>-7860.proxy.runpod.net`. **Пароля на интерфейсе нет — ссылку не раздавайте.**

Повторный запуск (под с volume): `bash /workspace/runpod-h3/start.sh`

## 3. В интерфейсе WanGP

1. Модель: **MiniMax H3 → FL2VA 33B** (или **Pruned 20B** — экономнее по ОЗУ) **→ PDD 8-Step**.
2. Category **720p** → **1280x704 (16:9)**, Number of frames: **124 = 5 с**, 243 = 10 с.
3. Первый запуск каждой модели скачивает веса (десятки ГБ).

Настройки выбора модели хранятся во вкладке — после обновления страницы выставьте заново.

## Команды

| | |
|---|---|
| `bash start.sh --status` | всё сразу: процесс, GPU, ОЗУ, OOM, диск, число роликов, последние перезапуски |
| `bash start.sh --logs` | живой лог WanGP (ошибки, шаги, `Video file saved`) |
| `bash start.sh --pack` | упаковать все ролики в `/workspace/h3-videos-*.tar` для скачивания через Jupyter |
| `bash start.sh --update` | обновить WanGP до свежей версии |
| `bash start.sh --stop` | остановить всё |

Ролики: `/workspace/Wan2GP/outputs/`. Логи: `/workspace/logs/`.

## Что уже исправлено в скриптах

| Проблема | Симптом | Решение |
|---|---|---|
| Gradio отвергает запросы через прокси RunPod | интерфейс открывается, но ничего не кликается (403 «Cross-origin request rejected») | `--public-url https://<POD_ID>-7860.proxy.runpod.net` |
| cuBLASLt на torch 2.10 + CUDA 13 | `CUBLAS_STATUS_NOT_INITIALIZED` на «Preparing Conditioning» | `DISABLE_ADDMM_CUDA_LT=1 TORCH_BLAS_PREFER_CUBLASLT=0` |
| Утечка ОЗУ в WanGP (~1.3 ГБ на ролик) | через несколько часов процесс молча умирает (OOM kill), прокси пишет «Waiting for service» | `supervisor.sh` поднимает WanGP через 5 с; `mem_guard.sh` перезапускает его заранее, когда ОЗУ > 88 ГБ и GPU простаивает |
| uv ставит Python на container disk | после рестарта пода venv на volume сломан | `UV_PYTHON_INSTALL_DIR=/workspace/.uv-python` |

После автоперезапуска обновите вкладку и выберите модель заново. Ролик, шедший в момент OOM, теряется.

## Настройки — `config.env`

`WANGP_REF` (закрепить версию), `PROFILE` (4 или 5 — меньше ОЗУ, медленнее), `MEM_GUARD_GB`, `TORCH_SPEC` / `TORCH_INDEX` (запасной вариант torch 2.8 + cu128 — в комментарии), `EXTRA_ARGS`.

## Перед Terminate

1. `bash start.sh --pack` → скачать архив через Jupyter.
2. Без volume всё остальное пропадёт — это нормально, следующий запуск всё поставит заново.
3. **Terminate**, а не Stop: остановленный под продолжает тарифицировать диск.

## Советы по цене

- Две сцены по 5 с дешевле одной на 10 с (10 с считается в ~2.8× дольше). Склейка — «Continue Video» в WanGP.
- Одна модель за сессию: переключение 20B ↔ 33B держит обе в ОЗУ и приближает OOM.
- Готовьте промпты заранее и ставьте пачкой в очередь — простой GPU тоже оплачивается.
