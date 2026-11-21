# Synthetic data

## Why fake data

The project is public and has to run on anyone's machine. That rules out real
tenant data, real credentials and real employer systems. Synthetic data also lets
tests set up awkward cases on purpose: duplicate serial numbers, users with no
account, devices with no user.

## Why it still looks real

Intune devices and Entra users are created as genuine Microsoft Graph SDK objects,
not hand-made lookalikes. Code that works on the fixtures should therefore work on
objects returned by `Get-MgDeviceManagementManagedDevice` and `Get-MgUser`. That
is still an assumption until it is tested against a live tenant.

The CMDB records are deliberately simple: five fields, loosely based on
Atlassian's hardware-asset schema. Real CMDBs vary too much for one schema to be
"correct".

## Where it lives

| File | Purpose |
| --- | --- |
| `data/*.csv` | One shared demonstration dataset used by every report and app |
| `data/test-*.csv` | Small fixtures that specific tests select on purpose |
| `tools/factories/` | Scripts that create and export the fake objects |

New reports reuse and extend the shared dataset rather than getting their own,
so every example stays consistent with the others.

## Changing it

`ParData` picks each file path in this order:

1. explicit paths passed when the module is imported;
2. the PSU variable `PAR_FixturePaths`;
3. the defaults in `data/`.

To add records, ask your agent to use the factory scripts with explicit values and
to keep the eleven `COMPARE-*` scenarios unchanged, because tests depend on them.
`Get-Help` on any factory or `ParData` command shows the exact fields.
