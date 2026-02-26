# Async FIFO 本地仿真冒烟项目（VCS + Verdi）

这个项目用于你在提交给验证人员之前，快速本地自检：
- 使用 **VCS** 编译/仿真
- 使用 **Verdi** 打开 FSDB 波形
- 使用一个 **Makefile** 完成编译、运行、看波形、清理

## 目录结构

```text
.
├── Makefile
├── rtl/
│   └── async_fifo.sv
├── tb/
│   └── tb_async_fifo_smoke.sv
└── sim/
    └── filelist.f
```

## 依赖

请确保你的环境已经配置好：
- `vcs`
- `verdi`
- FSDB dump 相关 PLI（通常由 Verdi 环境提供）

## 一键冒烟

```bash
make smoke
```

执行流程：
1. `make compile`：调用 VCS 生成 `sim/out/simv`
2. `make run`：运行仿真并输出 `sim/out/run.log`、`sim/out/wave.fsdb`

测试内容：
- 异步写时钟 (`wr_clk=100MHz`) / 异步读时钟 (`rd_clk≈71MHz`)
- 连续写入 `TEST_NUM=DEPTH*4` 笔数据
- 读端进行对拍检查，自动比较期望值与 `dout`
- 若有不一致，testbench 直接 `$fatal`

## 常用命令

```bash
make help      # 查看帮助
make compile   # 仅编译
make run       # 仅运行（需先 compile）
make verdi     # 打开 Verdi 并加载 FSDB
make clean     # 清理仿真产物
```

## 可选参数

```bash
make smoke SEED=123
```

## 交接给验证同事建议

你可以把下面内容作为交接说明：
- DUT：`rtl/async_fifo.sv`
- TB：`tb/tb_async_fifo_smoke.sv`
- filelist：`sim/filelist.f`
- 冒烟命令：`make smoke`
- 波形查看：`make verdi`

---

如果你后续要扩展成回归（多用例、多配置、覆盖率统计），可以在当前 Makefile 基础上继续加：
- `TEST=<case_name>`
- `COV=1` 开关（VCS coverage）
- 回归脚本（批量运行 + 汇总 PASS/FAIL）
