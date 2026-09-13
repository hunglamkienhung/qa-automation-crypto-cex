# qa-automation-crypto-cex

Kiểm thử tự động cho một **sàn giao dịch crypto tập trung** — swap, transfer,
bridge — dựng như một hệ thống chạy được chứ không phải slide. Một miền sàn được
test ở **đủ mọi tầng nó có** — cơ sở dữ liệu, API, và màn hình — bởi **hai stack
độc lập** (Node dùng Cucumber, Python dùng pytest-bdd) cùng đọc **một** bộ
Gherkin và phải cho **cùng một kết quả ở từng case**.

Không cần tài khoản, không cần key, không dịch vụ trả phí. Clone về là chạy.

[English](README.md) · [Kiến trúc](docs/ARCHITECTURE.md) ·
[Chấm điểm](docs/GRADING.md) · [Gherkin](docs/GHERKIN.md) · [Kịch bản demo](docs/DEMO.md)

## Hai hệ thống được test

| Hệ | Truy cập | Là gì |
|---|---|---|
| **mini-cex** | đọc + ghi, DB thật | Một sàn ký quỹ nhỏ trong `services/mini-cex`: một file SQLite, chỉ dùng thư viện chuẩn Node, một REST API, và các trang HTML có nhãn cho Playwright. |
| **Kraken public API** | chỉ đọc, chạy thật | Dữ liệu thị trường công khai của một sàn thật (`Assets`, `AssetPairs`, `Ticker`) — thế giới thật, không ai chỉnh cho pass được. |

`mini-cex` là nơi có các đường **ghi**, mỗi đường là một giao dịch:

- **transfer** — nạp, rút, và chuyển giữa hai tài khoản; từ chối thấu chi, ghi
  nợ/ghi có nguyên tử, ghi một dòng sổ cái tương ứng, idempotent theo key.
- **swap** — đổi spot A→B theo tỉ giá niêm yết; từ chối khi thiếu số dư hoặc quote
  dưới ngưỡng trượt giá, chốt tỉ giá, thu phí, ghi cả hai chân sổ cái.
- **bridge** — nạp/rút xuyên chuỗi dưới dạng máy trạng thái
  (`requested → locked → confirmed → credited`); idempotent theo tx ngoài, giới
  hạn mỗi giao dịch, và chỉ cho các chuỗi trong danh sách cho phép.

Số tiền lưu dạng số nguyên base units (1e8 mỗi coin), giá theo USD-micro, nên mọi
con số đều chính xác — không float trong đường tiền. Tầng Kraken live đối chiếu
danh sách asset và giá của mini-cex với một sàn thật.

## Hai ý đáng một phút

**Một bộ Gherkin, hai stack, một kết quả.** `features/*.feature` dùng chung.
`node/` chạy bằng Cucumber; `python/` chạy chính các file đó bằng pytest-bdd.
Lệch kết quả ở một case tự nó là một phát hiện — build đỏ vì nó.

**Failed > Blocked > Passed, và mất nguồn không bao giờ là Failed.** Một case chỉ
Failed khi một mệnh đề quan sát được và sai. Khi nguồn live (Kraken, service tắt)
không tới được thì case là **Blocked**. Cổng CI kiểm *hình dạng* lượt chạy so với
`fixtures/expected-results.json`, đỏ ở cả hai chiều.

## Chạy trong 30 giây

```bash
cd core/node && node --test "selftest/*.test.js"
cd ../python && pip install -e . && python -m pytest selftest -q
```

## Chạy cả bộ

```bash
bash scripts/run-be.sh node       # hoặc: python
bash scripts/run-fe.sh node       # cài sẵn chromium
bash scripts/gate.sh node         # cả bộ, rồi kiểm hình dạng lượt chạy
```

Cần: Node ≥ 22.13 (cho `node:sqlite`) và Python ≥ 3.11. Script FE tự cài trình
duyệt. Có sẵn devcontainer trong [.devcontainer/](.devcontainer/devcontainer.json).

## Phạm vi trung thực

`mini-cex` là một **mô hình dạy học** của sàn ký quỹ, không phải sàn thật: không
xác thực ngoài bearer handle, không giữ tài sản thật, và "bridge" là máy trạng
thái mô phỏng chứ không phải relayer on-chain. Điều đó là cố ý — nó làm các bất
biến đường-ghi (sổ cái cân, transfer không thấu chi, thao tác idempotent) test
được chính xác và hoàn toàn tất định. Tầng Kraken phụ thuộc bên thứ ba có thể
chậm hoặc giới hạn tần suất; các case đó chấm **Blocked**, không Failed.
