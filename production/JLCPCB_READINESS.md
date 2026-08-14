# JLCPCB assembly readiness

Catalog mapping checked against LCSC listings on 2026-08-14. `jlcpcb_sourcing.csv` is the controlled source of manufacturer part numbers, LCSC numbers, assembly status, and unresolved decisions. The PG1316S switches are intentionally excluded.

## Order blockers

There are no unresolved BOM mapping rows. Recheck every placement, side, rotation, stock status, and substituted part in JLCPCB's assembly viewer before payment.

Battery safety remains a release decision: J3 exposes only BATT and GND, so TH1 measures PCB temperature rather than cell temperature, and the BQ25895 can autonomously charge at its 2.048 A default while /CE is asserted. Do not release without documenting a battery pack rated for at least that charge current and with suitable independent thermal charge protection, or revising the hardware to sense the cell and prevent unsafe autonomous charging.

D1-D3 use Worldsemi WS2812B-2427-V6 (C52941389) on the 3.3 V rail. Its datasheet pinout is rotated 180 degrees relative to the former SK6805MICRO-J. The project-local `WS2812B-2427-V6_Rotated180` adapter footprint retains the legacy schematic pad numbers and routed copper locations while marking the replacement's physical pin 1 at the lower-right pad. The JLC output generator adds a 180-degree CPL correction for this MPN. Confirm that physical pin-1 orientation in the assembly viewer.

The routed board passed KiCad 10 ERC, PCB DRC, connectivity, and schematic-parity checks with zero reported violations on 2026-08-14. The fabrication archive, BOM, positions, IPC netlist, iBOM, and JLCPCB BOM/CPL were regenerated from the routed revision.

## Assembly exclusions

- SW3, SW4, SW5: PG1316S switches, sourced and fitted separately.
- J1: direct-soldered speaker wires.
- H1-H4 and TP1-TP4: non-component mechanical/test features.

## Release procedure

1. Resolve every row whose status is not `READY` or `EXCLUDED`.
2. Refill zones and rerun ERC, PCB DRC, connectivity, and schematic-parity checks after any design change.
3. Regenerate the fabrication package, BOM, CPL, and iBOM from the final saved board.
4. Upload BOM and CPL to JLCPCB and inspect every highlighted footprint, pin-1 marker, side, and rotation in the assembly viewer.

Component inventory changes continuously. Recheck every LCSC line in the JLCPCB assembly importer immediately before payment; the stock observations in this package are dated 2026-08-14.
