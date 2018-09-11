// add-on SSDT specific to models with Nvidia discrete GPU
// (will have no effect/ignored on models without)

DefinitionBlock("", "SSDT", 2, "hack", "_DGPU", 0)
{
    External(SB.PCI0.RP05.PEGP.LCTL, FieldUnitObj)
    External(SB.PCI0.RP05.PEGP.ELCT, IntObj)
    External(SB.PCI0.RP05.PEGP.VREG, FieldUnitObj)
    External(SB.PCI0.RP05.PEGP.VGAB, BuffObj)
    External(SB.PCI0.RP05.PEGP.VDID, FieldUnitObj)
    External(SB.PCI0.RP05.LNKD, FieldUnitObj)
    External(SB.PCI0.RP05.PEGP.HLRS, FieldUnitObj)
    External(SB.PCI0.RP05.PEGP.SGPO, MethodObj)

    // Patched HGOF to remove EC related code
    Method(SB.PCI0.RP05.PEGP.HGOF, 0, Serialized)
    {
        Store (LCTL, ELCT)
        Store (VREG, VGAB)
        Store (One, LNKD)
        While (LNotEqual (VDID, 0xFFFF))
        {
            Stall (0x64)
        }

        SGPO (HLRS, One)
        //Store (Zero, \_SB.PCI0.LPCB.EC0.NVPR)
        Store (Zero, LNKD)
        Return (Zero)
    }
}
//EOF
