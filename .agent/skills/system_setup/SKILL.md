---
name: System Hardware Detection & OS Provisioning
description: Automated hardware detection, kernel driver installation (T2 Mac / Generic PC), base package setup, and power management. Read before running setup on fresh Ubuntu installs.
---

# Agent Skill: System Hardware Detection & OS Provisioning

## Purpose
Guide the AI Agent to inspect hardware capabilities, choose appropriate driver packages, disable laptop sleep/lid-close hooks, and run initial base OS provisioning.

## Hardware Classification Matrix
| Hardware Category | Detection Signature | Required Action |
|---|---|---|
| **Apple T2 MacBook** (2018-2020) | `sys_vendor` contains "Apple", `product_name` contains "MacBookPro15" | Run `hardware/t2-mac/install_t2_drivers.sh`, reboot if fresh kernel installed. |
| **Generic Laptop** | `chassis_type` is 9 or 10, non-Apple | Run `hardware/laptop-power/configure_power.sh`. |
| **Desktop / NUC / Mini PC / VPS** | `chassis_type` is 3, 6, 7, or Cloud VM | Skip custom kernels & lid power management. |

## Agent Execution Checklist
1. **Privilege Check**: Verify command execution with `sudo` or `root` user (`[ "$EUID" -eq 0 ]`).
2. **Execute Automated Orchestrator**:
   ```bash
   sudo ./bin/setup.sh --auto
   ```
3. **Hardware-Specific Commands**:
   - For T2 Mac manually: `sudo bash hardware/t2-mac/install_t2_drivers.sh`
   - For Laptop Power manually: `sudo bash hardware/laptop-power/configure_power.sh`
4. **Verification**:
   - Verify kernel: `uname -r`
   - Verify power lid ignore settings: `cat /etc/systemd/logind.conf | grep HandleLidSwitch`
