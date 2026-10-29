# YAPP Router UVM Verification

SystemVerilog/UVM verification coursework by Ang Chen, completed during Cadence’s *SystemVerilog Accelerated Verification with UVM* training.

**Repository status:** Selected source files; external training components are required for simulation.

## Project Scope

The router receives YAPP packets and routes valid traffic to three output channels. Each packet contains a 6-bit payload length, 2-bit destination, byte payload, and XOR parity byte. HBUS accesses configure router enable and maximum packet length.

A reference model predicts packet forwarding or dropping based on destination and configuration. A per-channel queue scoreboard compares expected and observed packet address, length, payload, and parity.

## Implementation Highlights

- YAPP transmit agent with driver, monitor, sequencer, and active/passive configuration.
- Constrained-random packet generation with configurable length, destination, delay, and parity.
- Directed sequences targeting routing, incremental payloads, length boundaries, invalid destinations, and bad parity.
- Reference model and queue-based scoreboard, with a TLM analysis FIFO scoreboard retained as an alternative.
- Virtual sequences coordinating HBUS configuration and packet traffic.
- Generated RAL model integration with frontdoor/backdoor accesses and auto-prediction.

## Source Organization

| Directory | Contents |
| --- | --- |
| `yapp/sv/` | Packet model, interface, transmit agent, sequences, and package |
| `router/sv/` | Reference model, scoreboards, and module environment |
| `tb/` | System environment, virtual sequencer, register sequences, and UVM top |
| `docs/` | Archived topology output |

The environment uses a reference model and per-channel queue scoreboard to verify packet routing. A FIFO-based scoreboard is included as an alternative implementation.

## Functional Coverage and Assertions

The YAPP monitor samples completed input packets.

| Coverage Item | Bins |
| --- | --- |
| Payload length | 1; 2–10; 11–40; 41–62; 63 |
| Destination | 0, 1, 2, and invalid destination 3 |
| Parity | Good and bad |
| Crosses | Length × destination; length × valid destination × bad parity |

The interface includes a reset-disabled assertion checking suspension duration against a 20-cycle limit. Coverage measures input stimulus; scoreboards check forwarding and packet contents.

## Register Integration

The environment connects an externally generated RAL model to the HBUS sequencer through an adapter and enables auto-prediction. Register sequences exercise frontdoor reads/writes and backdoor peek/poke operations.

Raw HBUS accesses outside RAL do not automatically update the RAL mirror. The checking model does not predict parity-error counter values.

## Dependencies

The complete simulation requires external router RTL, HBUS/channel/clock-reset UVCs, generated register files, hardware top, and test library.

Development used Cadence Xcelium. Mid-traffic reset requires additional checker-state and RAL synchronization.

## Attribution

Developed using the Cadence *SystemVerilog Accelerated Verification with UVM v1.2.6* lab manual, including reference-model, scoreboard, TLM FIFO, and register-integration exercises.

Supplied components and template portions remain subject to their applicable training terms.