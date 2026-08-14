# JLCPCB assembly readiness

Catalog mapping checked against LCSC listings on 2026-08-14. `jlcpcb_sourcing.csv` is the controlled source of manufacturer part numbers, LCSC numbers, assembly status, and unresolved decisions. The PG1316S switches are intentionally excluded.

## Order blockers

1. Decide whether R25 really requires the schematic's 0.1% shunt tolerance. The available selected JLC part is 50 mOhm, 1%, 1 W in 1206; do not silently relabel it as 0.1%.
2. R15 C137669 was catalogued but showed zero LCSC stock when checked. Select an exact 953 kOhm 1% 0603 alternate if still unavailable at order time.
3. Recheck every placement, side, rotation, and substituted part in JLCPCB's assembly viewer before payment.

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
