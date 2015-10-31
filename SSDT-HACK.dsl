// Instead of providing patched DSDT/SSDT, just include a single SSDT
// and do the rest of the work in config.plist

// A bit experimental, and a bit more difficult with laptops, but
// still possible.

// Note: No solution for missing IAOE here, but so far, not a problem.

DefinitionBlock ("SSDT-HACK.aml", "SSDT", 1, "hack", "hack", 0x00003000)
{
    External(\_SB.PCI0, DeviceObj)
    External(\_SB.PCI0.LPCB, DeviceObj)
    External(\_SB.PCI0.LPCB.PS2K, DeviceObj)
    External(\_SB.PCI0.LPCB.EC0, DeviceObj)
    External(\_SB.PCI0.LPCB.EC0.XQ94, MethodObj)
    External(\_SB.PCI0.LPCB.EC0.TPDS, FieldUnitObj)
    External(\_SB.PCI0.LPCB.EC0.BLIS, FieldUnitObj)
    External(\_SB.PCI0.LPCB.EC0.ECOK, IntObj)
    External(\_SB.PCI0.LPCB.EC0.RTMP, FieldUnitObj)

    External(\_SB.PCI0.HDEF, DeviceObj)
    External(\_SB.PCI0.HDAU, DeviceObj)
    External(\_SB.PCI0.IGPU, DeviceObj)
    External(\_SB.PCI0.EH01, DeviceObj)
    External(\_SB.PCI0.EH02, DeviceObj)
    External(\_SB.PCI0.XHC, DeviceObj)

    External(\_SB.BAT1, DeviceObj)
 
    // All _OSI calls in DSDT are routed to XOSI...
    // XOSI simulates "Windows 2009" (which is Windows 7)
    // Note: According to ACPI spec, _OSI("Windows") must also return true
    //  Also, it should return true for all previous versions of Windows.
    Method(XOSI, 1)
    {
        // simulation targets
        // source: (google 'Microsoft Windows _OSI')
        //  http://download.microsoft.com/download/7/E/7/7E7662CF-CBEA-470B-A97E-CE7CE0D98DC2/WinACPI_OSI.docx
        Store(Package()
        {
            "Windows",              // generic Windows query
            "Windows 2001",         // Windows XP
            "Windows 2001 SP2",     // Windows XP SP2
            //"Windows 2001.1",     // Windows Server 2003
            //"Windows 2001.1 SP1", // Windows Server 2003 SP1
            "Windows 2006",         // Windows Vista
            "Windows 2006 SP1",     // Windows Vista SP1
            //"Windows 2006.1",     // Windows Server 2008
            "Windows 2009",         // Windows 7/Windows Server 2008 R2
            //"Windows 2012",       // Windows 8/Windows Sesrver 2012
            //"Windows 2013",       // Windows 8.1/Windows Server 2012 R2
            //"Windows 2015",       // Windows 10/Windows Server TP
        }, Local0)
        Return (LNotEqual(Match(Local0, MEQ, Arg0, MTR, 0, 0), Ones))
    }

    // In DSDT, native GPRW is renamed to XPRW with Clover binpatch.
    // As a result, calls to GPRW land here.
    // The purpose of this implementation is to avoid "instant wake"
    // by returning 0 in the second position (sleep state supported)
    // of the return package.
    Method(GPRW, 2)
    {
        If (LEqual(Arg0, 0x6d)) { Return(Package() { 0x6d, 0, }) }
        External(\XPRW, MethodObj)
        Return(XPRW(Arg0, Arg1))
    }

    // For backlight control
    Device(PNLF)
    {
        Name(_ADR, Zero)
        Name(_HID, EisaId ("APP0002"))
        Name(_CID, "backlight")
        Name(_UID, 10)
        Name(_STA, 0x0B)
        Method(RMCF)
        {
            Return(Package()
            {
                "PWMMax", 0,
            })
        }
        Method(_INI)
        {
            // disable discrete graphics (Nvidia) if it is present
            External(\_SB.PCI0.RP05.PEGP._OFF, MethodObj)
            If (CondRefOf(\_SB.PCI0.RP05.PEGP._OFF))
            {
                \_SB.PCI0.RP05.PEGP._OFF()
            }
        }
    }

    Scope (\_SB.PCI0.LPCB.PS2K)
    {
        // Select specific keyboard map in VoodooPS2Keyboard.kext
        Method(_DSM, 4)
        {
            If (LEqual (Arg2, Zero)) { Return (Buffer() { 0x03 } ) }
            Return (Package()
            {
                "RM,oem-id", "LENOVO",
                "RM,oem-table-id", "U430-RMCF",
            })
        }

        // overrides for VoodooPS2 configuration...
        Name(RMCF, Package()
        {
            "Controller", Package()
            {
                "WakeDelay", 0,
            },
            "Sentelic FSP", Package()
            {
                "DisableDevice", ">y",
            },
            "ALPS GlidePoint", Package()
            {
                "DisableDevice", ">y",
            },
            "Mouse", Package()
            {
                "DisableDevice", ">y",
            },
            "Synaptics TouchPad", Package()
            {
                "MultiFingerVerticalDivisor", 9,
                "MultiFingerHorizontalDivisor", 9,
                "MomentumScrollThreshY", 12,
            },
            "Keyboard", Package()
            {
                "Breakless PS2", Package()
                {
                    Package(){}, // indicates array
                    "e064",
                    "e065",
                    "e068",
                    "e06a",
                    "e027",
                },
                "MaximumMacroTime", 25000000,
                "Macro Inversion", Package()
                {
                    Package(){},
                    // Fn+F4
                    Buffer() { 0xff, 0xff, 0x02, 0x64, 0x00, 0x00, 0x00, 0x00, 0x01, 0x38, 0x01, 0x3e },
                    Buffer() { 0xff, 0xff, 0x02, 0xe4, 0x00, 0x00, 0x00, 0x00, 0x01, 0xbe, 0x01, 0xb8 },
                    // F5 (without Fn)
                    Buffer() { 0xff, 0xff, 0x02, 0x65, 0x01, 0x00, 0x00, 0x00, 0x01, 0x3f },
                    Buffer() { 0xff, 0xff, 0x02, 0xe5, 0x01, 0x00, 0x00, 0x00, 0x01, 0xbf },
                    // Fn+Ctrl+F6
                    Buffer() { 0xff, 0xff, 0x02, 0x27, 0x00, 0x03, 0xff, 0xff, 0x02, 0x66 },
                    Buffer() { 0xff, 0xff, 0x02, 0xa7, 0x00, 0x03, 0xff, 0xff, 0x02, 0xe6 },
                    // Ctrl+F6
                    Buffer() { 0xff, 0xff, 0x02, 0x27, 0x00, 0x03, 0xff, 0xff, 0x02, 0x40 },
                    Buffer() { 0xff, 0xff, 0x02, 0xa7, 0x00, 0x03, 0xff, 0xff, 0x02, 0xc0 },
                    // Fn+F8
                    Buffer() { 0xff, 0xff, 0x02, 0x68, 0x00, 0x00, 0x00, 0x00, 0x02, 0x1d, 0x01, 0x38, 0x01, 0x0f },
                    Buffer() { 0xff, 0xff, 0x02, 0xe8, 0x00, 0x00, 0x00, 0x00, 0x01, 0x8f, 0x01, 0xb8, 0x02, 0x9d },
                    // Fn+F10
                    Buffer() { 0xff, 0xff, 0x02, 0x6a, 0x00, 0x00, 0x00, 0x00, 0x02, 0x5b, 0x01, 0x19 },
                    Buffer() { 0xff, 0xff, 0x02, 0xea, 0x00, 0x00, 0x00, 0x00, 0x01, 0x99, 0x02, 0xdb },
                },
                "Custom ADB Map", Package()
                {
                    Package(){},
                    "e063=3f", // Apple Fn
                    "e064=6b", // F14
                    "e065=71", // F15
                    "e068=4f", // F18
                    "e0f2=65", // special F9
                    "e0fb=91", // brightness down
                    "e0fc=90", // brightness up
                    "e06a=70", // video mirror
                },
                "Custom PS2 Map", Package()
                {
                    Package(){},
                    "e037=64", // PrtSc=F13
                },
                "Function Keys Special", Package()
                {
                    Package(){},
                    // The following 12 items map Fn+fkeys to Fn+fkeys
                    "e020=e020",
                    "e02e=e02e",
                    "e030=e030",
                    "e064=e064",
                    "e065=e065",
                    "e066=e028",
                    "e067=e067",
                    "e068=e068",
                    "e069=e0f0",
                    "e06a=e06a",
                    "e06b=e0fb",
                    "e06c=e0fc",
                    // The following 12 items map fkeys to fkeys
                    "3b=3b",
                    "3c=3c",
                    "3d=3d",
                    "3e=3e",
                    "3f=3f",
                    "40=40",
                    "41=41",
                    "42=42",
                    "43=43",
                    "44=44",
                    "57=57",
                    "58=58",
                },
                "Function Keys Standard", Package()
                {
                    Package(){},
                    // The following 12 items map Fn+fkeys to fkeys
                    "e020=3b",
                    "e02e=3c",
                    "e030=3d",
                    "e064=3e",
                    "e065=3f",
                    "e066=40",
                    "e067=41",
                    "e068=42",
                    "e069=e0f2",
                    "e06a=44",
                    "e06b=57",
                    "e06c=58",
                    // The following 12 items map fkeys to Fn+fkeys
                    "3b=e020",
                    "3c=e02e",
                    "3d=e030",
                    "3e=e064",
                    "3f=e065",
                    "40=e028",
                    "41=e067",
                    "42=e068",
                    "43=e0f1",
                    "44=e06a",
                    "57=e0fb",
                    "58=e0fc",
                },
            },
        })

        // RKAB/RKAC called for PS2 code e0fb/e0fc (brightness is mapped to it)
        Method(RKAB, 1)
        {
            // if screen is turned off, turn it on...
            If (LNot(\_SB.PCI0.LPCB.EC0.BLIS))
            {
                Store (1, \_SB.PCI0.LPCB.EC0.BLIS)
                \_SB.PCI0.LPCB.EC0.XQ94()
                \_SB.PCI0.LPCB.EC0._Q41()
            }
        }
        Method(RKAC, 1) { RKAB(Arg0) }
        // RKA0 called for PS2 code e0f0 (mapped from normal Fn+F9)
        // RKA1 called for PS2 code e0f1 (mapped from F9, with keys swapped)
        // RKA2 called for PS2 code e0f2 (mapped from Fn+F9, with keys swapped)
        Method (RKA0, 1)
        {
            If (Arg0)
            {
                // normal action for Fn+F9 (without keys swapped, toggle screen)
                \_SB.PCI0.LPCB.EC0.XQ94()
                \_SB.PCI0.LPCB.EC0._Q41()
            }
        }
        Method(RKA1, 1)
        {
            If (Arg0)
            {
                // F9 with keys swapped, do what EC would do (toggle screen)
                Store(LNot(\_SB.PCI0.LPCB.EC0.BLIS), \_SB.PCI0.LPCB.EC0.BLIS)
                RKA0(Arg0)
            }
        }
        Method(RKA2, 1)
        {
            If (Arg0)
            {
                // Fn+F9 with keys swapped, undo what EC would do (avoid toggling screen)
                Store(LNot(\_SB.PCI0.LPCB.EC0.BLIS), \_SB.PCI0.LPCB.EC0.BLIS)
            }
        }
    }

    Scope(\_SB.PCI0.LPCB.EC0)
    {
        // The native _Qxx methods in DSDT are renamed XQxx,
        // so notifications from the EC driver will land here.

        // _Q91 (Fn+F11) called on brightness down key
        Method(_Q91)
        {
            // e06b: code for brightness down
            Notify (\_SB.PCI0.LPCB.PS2K, 0x046b)
        }
        //_Q90 (Fn+F12) called on brightness up key
        Method(_Q90)
        {
            // e06c: code for brightness up
            Notify (\_SB.PCI0.LPCB.PS2K, 0x046c)
        }
        Method(_Q94)
        {
            // e069 will be mapped to either F10 (44) or e0f0 or e0f2
            Notify (\_SB.PCI0.LPCB.PS2K, 0x0469)
        }
        Method(_Q8F)
        {
            // EC toggles TPDS when this key is struck before arriving here
            // We can cancel the toggle by setting TPDS=1 (trackpad enabled)
            Store(1, TPDS)
            // e066 will be mapped to either F6 (40) or e037
            Notify (\_SB.PCI0.LPCB.PS2K, 0x0466)
        }
        Method(_Q41)
        {
            // e067 will be mapped to either F7 (41) or itself
            //Notify (\_SB.PCI0.LPCB.PS2K, 0x0467)
        }
    }

    Scope(\_SB.PCI0.LPCB.EC0)
    {
        // This is an override for battery methods that access EC fields
        // larger than 8-bit.

        OperationRegion (ERM2, EmbeddedControl, Zero, 0xFF)
        Field (ERM2, ByteAcc, NoLock, Preserve)
        {
            Offset (0xC1),
            MCU0, 8, MCU1, 8,
            MBR0, 8, MBR1, 8,
            MBV0, 8, MBV1, 8,
            //Offset (0xDE),
            //,/*EBLV,*/   8,
            //,   6,
            //,/*APWR,*/   1,
            //,/*DLYE,*/   1,
            Offset(0xE0),
            B1F0, 8, B1F1, 8,
        }
        Field (ERM2, ByteAcc, NoLock, Preserve)
        {
            Offset (0xA0),
            DIC0, 8, DIC1, 8,
            DIV0, 8, DIV1, 8
        }
        Field (ERM2, ByteAcc, NoLock, Preserve)
        {
            Offset (0xA0),
            //SBDN, 128,
            DN00,8,DN01,8,DN02,8,DN03,8,DN04,8,DN05,8,DN06,8,DN07,8,DN08,8,DN09,8,DN0A,8,DN0B,8,DN0C,8,DN0D,8,DN0E,8,DN0F,8,
        }
        Field (ERM2, ByteAcc, NoLock, Preserve)
        {
            Offset (0xA0),
            //SBMN, 128,
            MN00,8,MN01,8,MN02,8,MN03,8,MN04,8,MN05,8,MN06,8,MN07,8,MN08,8,MN09,8,MN0A,8,MN0B,8,MN0C,8,MN0D,8,MN0E,8,MN0F,8,
        }
        Method (RDDN, 0, Serialized)
        {
            Name (TEMP, Buffer(0x10) { })
            Store (DN00, Index(TEMP, 0x00))
            Store (DN01, Index(TEMP, 0x01))
            Store (DN02, Index(TEMP, 0x02))
            Store (DN03, Index(TEMP, 0x03))
            Store (DN04, Index(TEMP, 0x04))
            Store (DN05, Index(TEMP, 0x05))
            Store (DN06, Index(TEMP, 0x06))
            Store (DN07, Index(TEMP, 0x07))
            Store (DN08, Index(TEMP, 0x08))
            Store (DN09, Index(TEMP, 0x09))
            Store (DN0A, Index(TEMP, 0x0A))
            Store (DN0B, Index(TEMP, 0x0B))
            Store (DN0C, Index(TEMP, 0x0C))
            Store (DN0D, Index(TEMP, 0x0D))
            Store (DN0E, Index(TEMP, 0x0E))
            Store (DN0F, Index(TEMP, 0x0F))
            Return (TEMP)
        }
        Method (RDMN, 0, Serialized)
        {
            Name (TEMP, Buffer(0x10) { })
            Store (MN00, Index(TEMP, 0x00))
            Store (MN01, Index(TEMP, 0x01))
            Store (MN02, Index(TEMP, 0x02))
            Store (MN03, Index(TEMP, 0x03))
            Store (MN04, Index(TEMP, 0x04))
            Store (MN05, Index(TEMP, 0x05))
            Store (MN06, Index(TEMP, 0x06))
            Store (MN07, Index(TEMP, 0x07))
            Store (MN08, Index(TEMP, 0x08))
            Store (MN09, Index(TEMP, 0x09))
            Store (MN0A, Index(TEMP, 0x0A))
            Store (MN0B, Index(TEMP, 0x0B))
            Store (MN0C, Index(TEMP, 0x0C))
            Store (MN0D, Index(TEMP, 0x0D))
            Store (MN0E, Index(TEMP, 0x0E))
            Store (MN0F, Index(TEMP, 0x0F))
            Return (TEMP)
        }
        Method (\B1B2, 2, NotSerialized) { Return (Or (Arg0, ShiftLeft (Arg1, 8))) }
        
        External(\_SB.BATM, MutexObj)
        External(\_SB.BAT1.PBIF, PkgObj)
        External(\_SB.PCI0.LPCB.EC0.WAEC, MethodObj)
        External(\_SB.PCI0.LPCB.EC0.WADR, MethodObj)
        External(\_SB.PCI0.LPCB.EC0.CREC, MethodObj)
        External(\_SB.PCI0.LPCB.EC0.HIID, FieldUnitObj)

        // UPBI and UPBS in DSDT are renamed to XPBI and XPBS.  As a result,
        // calls from _BST, _BIF land here, where we can deal with
        // OS X limitations regarding EC fields larger than 8-bit

        Method (\_SB.BAT1.UPBI, 0, NotSerialized)
        {
            Acquire (BATM, 0xFFFF)
            Store (Zero, Index (PBIF, Zero))
            Multiply (B1B2 (^^PCI0.LPCB.EC0.B1F0, ^^PCI0.LPCB.EC0.B1F1), 0x0A, Index (PBIF, 0x02))
            ^^PCI0.LPCB.EC0.WAEC ()
            Store (0x02, ^^PCI0.LPCB.EC0.HIID)
            ^^PCI0.LPCB.EC0.WADR ()
            Multiply (B1B2 (^^PCI0.LPCB.EC0.DIC0, ^^PCI0.LPCB.EC0.DIC1), 0x0A, Local1)
            Store (Local1, Index (PBIF, One))
            Store (B1B2 (^^PCI0.LPCB.EC0.DIV0, ^^PCI0.LPCB.EC0.DIV1), Index (PBIF, 0x04))
            ^^PCI0.LPCB.EC0.CREC ()
            Store (Divide (Local1, 0x0A, ), Index (PBIF, 0x05))
            Store (Divide (Multiply (Local1, 0x02), 0x64, ), Index (PBIF, 0x06
            ))
            ^^PCI0.LPCB.EC0.WAEC ()
            Store (0x06, ^^PCI0.LPCB.EC0.HIID)
            ^^PCI0.LPCB.EC0.WADR ()
            Store (^^PCI0.LPCB.EC0.RDDN(), Index (PBIF, 0x09))
            ^^PCI0.LPCB.EC0.CREC ()
            Store ("LION", Index (PBIF, 0x0B))
            ^^PCI0.LPCB.EC0.WAEC ()
            Store (0x05, ^^PCI0.LPCB.EC0.HIID)
            ^^PCI0.LPCB.EC0.WADR ()
            Store (^^PCI0.LPCB.EC0.RDMN(), Index (PBIF, 0x0C))
            ^^PCI0.LPCB.EC0.CREC ()
            Release (BATM)
        }
        
        External(\_SB.POSW, MethodObj)
        External(\_SB.BAT1.PBST, PkgObj)
        External(\_SB.PCI0.LPCB.EC0.MBTF, FieldUnitObj)
        External(\_SB.PCI0.LPCB.EC0.MBWC, FieldUnitObj)
        External(\_SB.PCI0.LPCB.EC0.MBDS, FieldUnitObj)

        Method (\_SB.BAT1.UPBS, 0, NotSerialized)
        {
            Store (B1B2 (^^PCI0.LPCB.EC0.MCU0, ^^PCI0.LPCB.EC0.MCU1), Local5)
            Multiply (POSW (Local5), 0x0A, Index (PBST, One))
            Multiply (B1B2 (^^PCI0.LPCB.EC0.MBR0, ^^PCI0.LPCB.EC0.MBR1), 0x0A, Index (PBST, 0x02))
            Store (B1B2 (^^PCI0.LPCB.EC0.MBV0, ^^PCI0.LPCB.EC0.MBV1), Index (PBST, 0x03))
            If (^^PCI0.LPCB.EC0.MBTF)
            {
                Store (Zero, Index (PBST, Zero))
            }
            Else
            {
                If (LNotEqual (Local5, Zero))
                {
                    If (^^PCI0.LPCB.EC0.MBWC)
                    {
                        Store (0x02, Index (PBST, Zero))
                    }
                    Else
                    {
                        If (^^PCI0.LPCB.EC0.MBDS)
                        {
                            Store (One, Index (PBST, Zero))
                        }
                        Else
                        {
                            Store (Zero, Index (PBST, Zero))
                        }
                    }
                }
                Else
                {
                    If (^^PCI0.LPCB.EC0.MBWC)
                    {
                        Store (0x02, Index (PBST, Zero))
                    }
                    Else
                    {
                        Store (Zero, Index (PBST, Zero))
                    }
                }
            }
        }
    }

    Scope (\_SB.PCI0)
    {
        Device(IMEI)
        {
            Name (_ADR, 0x00160000)
        }

        Device(SBUS.BUS0)
        {
            Name(_CID, "smbus")
            Name(_ADR, Zero)
            Device(DVL0)
            {
                Name(_ADR, 0x57)
                Name(_CID, "diagsvault")
                Method(_DSM, 4)
                {
                    If (LEqual (Arg2, Zero)) { Return (Buffer() { 0x03 } ) }
                    Return (Package() { "address", 0x57 })
                }
            }
        }

// Note: All the _DSM injects below could be done in config.plist/Devices/Arbitrary
//  For now, using config.plist instead of _DSM methods.
/*
        // inject properties for onboard audio
        Method(HDEF._DSM, 4)
        {
            If (LEqual(Arg2, Zero)) { Return (Buffer() { 0x03 } ) }
            Return (Package()
            {
                "layout-id", Buffer() { 3, 0, 0, 0, },
                "PinConfigurations", Buffer(Zero) {},
            })
        }

        // inject properties for HDMI audio on HDAU
        Method(HDAU._DSM, 4)
        {
            If (LEqual(Arg2, Zero)) { Return (Buffer() { 0x03 } ) }
            Return (Package()
            {
                "layout-id", Buffer() { 3, 0, 0, 0, },
                "hda-gfx", Buffer() { "onboard-1" },
            })
        }

        // inject properties for HDMI audio on IGPU
        Method(IGPU._DSM, 4)
        {
            If (LEqual(Arg2, Zero)) { Return (Buffer() { 0x03 } ) }
            Return (Package()
            {
                "hda-gfx", Buffer() { "onboard-1" },
            })
        }

        // inject properties for USB: EHC1/EHC2/XHC
        Method(EH01._DSM, 4)
        {
            If (LEqual(Arg2, Zero)) { Return (Buffer() { 0x03 } ) }
            Return (Package()
            {
                "subsystem-id", Buffer() { 0x70, 0x72, 0x00, 0x00 },
                "subsystem-vendor-id", Buffer() { 0x86, 0x80, 0x00, 0x00 },
                "AAPL,current-available", 2100,
                "AAPL,current-extra", 2200,
                "AAPL,current-extra-in-sleep", 1600,
                //"AAPL,device-internal", 0x02,
                "AAPL,max-port-current-in-sleep", 2100,
            })
        }

        // Note: EHCI #2 is not really active on the u430
        Method(EH02._DSM, 4)
        {
            If (LEqual(Arg2, Zero)) { Return (Buffer() { 0x03 } ) }
            Return (Package()
            {
                "subsystem-id", Buffer() { 0x70, 0x72, 0x00, 0x00 },
                "subsystem-vendor-id", Buffer() { 0x86, 0x80, 0x00, 0x00 },
                "AAPL,current-available", 2100,
                "AAPL,current-extra", 2200,
                "AAPL,current-extra-in-sleep", 1600,
                //"AAPL,device-internal", 0x02,
                "AAPL,max-port-current-in-sleep", 2100,
            })
        }

        Method(XHC._DSM, 4)
        {
            If (LEqual(Arg2, Zero)) { Return (Buffer() { 0x03 } ) }
            Return (Package()
            {
                "subsystem-id", Buffer() { 0x70, 0x72, 0x00, 0x00 },
                "subsystem-vendor-id", Buffer() { 0x86, 0x80, 0x00, 0x00 },
                "AAPL,current-available", 2100,
                "AAPL,current-extra", 2200,
                "AAPL,current-extra-in-sleep", 1600,
                //"AAPL,device-internal", 0x02,
                "AAPL,max-port-current-in-sleep", 2100,
            })
        }
 */
    }

    Device (SMCD)
    {
        Name (_HID, "FAN00000") // _HID: Hardware ID
        // ACPISensors.kext configuration
        //    Name (TACH, Package()
        //    {
        //        "System Fan", "FAN0",
        //    })
        Name (TEMP, Package()
        {
            "CPU Heatsink", "TCPU",
            //"Ambient", "TAMB",
            //"Mainboard", "TSYS",
            //"CPU Proximity", "TCPP",
        })
        //Name (KLVN, 1)
        // Actual methods to implement fan/temp readings/control
        //    Method (FAN0, 0, Serialized)
        //    {
        //    }
        Method (TCPU, 0, Serialized)
        {
            //Return (\_TZ.TZ00._TMP())
            //Return(Divide(Subtract(\_TZ.TZ00._TMP(), 2732), 10))
            If (\_SB.PCI0.LPCB.EC0.ECOK) { Store(\_SB.PCI0.LPCB.EC0.RTMP, Local0) }
            Else { Store(0x1A, Local0) }
            Return(Local0)
        }
        //	Method (TAMB, 0, Serialized) // Ambient Temp
        //	{
        //	}
    }
}

