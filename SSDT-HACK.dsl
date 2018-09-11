// Main add-on SSDT for u430/u330/u550
DefinitionBlock("", "SSDT", 2, "hack", "_HACK", 0)
{
    External(_SB.PCI0, DeviceObj)
    External(_SB.PCI0.LPCB, DeviceObj)

    // All _OSI calls in DSDT are routed to XOSI...
    // XOSI simulates "Windows 2012" (which is Windows 8)
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
            "Windows 2012",         // Windows 8/Windows Server 2012
            //"Windows 2013",       // Windows 8.1/Windows Server 2012 R2
            //"Windows 2015",       // Windows 10/Windows Server TP
        }, Local0)
        Return (Ones != Match(Local0, MEQ, Arg0, MTR, 0, 0))
    }

//
// ACPISensors configuration (ACPISensors.kext is not installed by default)
//

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
            If (\_SB.PCI0.LPCB.EC.ECOK) { Local0 = \_SB.PCI0.LPCB.EC.RTMP }
            Else { Local0 = 0x1a }
            Return(Local0)
        }
        //Method (TAMB, 0, Serialized) // Ambient Temp
        //{
        //}
    }

//
// USB related
//
#if 0
    // In DSDT, native GPRW is renamed to XPRW with Clover binpatch.
    // As a result, calls to GPRW land here.
    // The purpose of this implementation is to avoid "instant wake"
    // by returning 0 in the second position (sleep state supported)
    // of the return package.
    Method(GPRW, 2)
    {
        If (0x6d == Arg0) { Return(Package() { 0x6d, 0, }) }
        External(\XPRW, MethodObj)
        Return(XPRW(Arg0, Arg1))
    }
#else
    Name(_SB.PCI0.EH01._STA, 0)
    Name(_SB.PCI0.EH02._STA, 0)
#endif
    // In DSDT, native XSEL is renamed XXEL with Clover binpatch.
    // Calls to it will land here.
    External(_SB.PCI0.XHC, DeviceObj)
    External(_SB.PCI0.XHC.PR2, FieldUnitObj)
    External(_SB.PCI0.XHC.PR2M, FieldUnitObj)
    External(_SB.PCI0.XHC.PR3, FieldUnitObj)
    External(_SB.PCI0.XHC.PR3M, FieldUnitObj)
    // Note about path of XUSB. In DSDT, it is declared as follows:
    //
    //Scope (\_SB)
    //{
    //    OperationRegion (PCI0.LPCB.LPC1, PCI_Config, Zero, 0x0100)
    //    Field (PCI0.LPCB.LPC1, AnyAcc, NoLock, Preserve)
    //    {
    //        //...
    //        XUSB,   1
    //    }
    //
    // Initially assumed the full path for XUSB was \_SB.PCI0.LPCB.XUSB, but it is
    // actually \_SB.XUSB.  The path in OperationRegion/Field only locates
    // the particular PCI_Config, but the symbols within Field are scoped to
    // \_SB.  It is a handy little feature that may be useful in other cases...
    External(_SB.XUSB, FieldUnitObj)
    External(_SB.PCI0.XHC.XRST, IntObj)
    Method(_SB.PCI0.XHC.XSEL)
    {
        // This code is based on original XSEL, but without all the conditionals
        // With this code, USB works correctly even in 10.10 after booting Windows
        // setup to route all USB2 on XHCI to XHCI (not EHCI, which is disabled)
        Store(1, XUSB)
        Store(1, XRST)
        Or(And (PR3, 0xFFFFFFC0), PR3M, PR3)
        Or(And (PR2, 0xFFFF8000), PR2M, PR2)
    }

    // Override for USBInjectAll.kext
    Device(UIAC)
    {
        Name(_HID, "UIA00000")
        Name(RMCF, Package()
        {
            // EH01 has no ports (XHCIMux is used to force USB3 routing OFF)
            "EH01", Package()
            {
                "port-count", Buffer() { 0, 0, 0, 0 },
                "ports", Package() { },
            },
            // XHC overrides
            "8086_9xxx", Package()
            {
                //"port-count", Buffer() { 0x0d, 0, 0, 0},
                "ports", Package()
                {
                    "HS01", Package() // touchscreen
                    {
                        "UsbConnector", 255,
                        "port", Buffer() { 0x01, 0, 0, 0 },
                    },
                    "HS02", Package() // HS USB3 left
                    {
                        "UsbConnector", 3,
                        "port", Buffer() { 0x02, 0, 0, 0 },
                    },
                    "HS03", Package() // USB2 far right
                    {
                        "UsbConnector", 0,
                        "port", Buffer() { 0x03, 0, 0, 0 },
                    },
                    "HS04", Package() // USB2 near right
                    {
                        "UsbConnector", 0,
                        "port", Buffer() { 0x04, 0, 0, 0 },
                    },
                    "HS05", Package() // camera
                    {
                        "UsbConnector", 255,
                        "port", Buffer() { 0x05, 0, 0, 0 },
                    },
                    "HS06", Package() // bluetooth
                    {
                        "UsbConnector", 255,
                        "port", Buffer() { 0x06, 0, 0, 0 },
                    },
                    "SS01", Package() // SS USB3 left
                    {
                        "UsbConnector", 3,
                        "port", Buffer() { 0x0a, 0, 0, 0 },
                    },
                },
            },
        })
    }

//
// Disabling EHCI #1
//

    External(_SB.PCI0.EH01, DeviceObj)
    Scope(_SB.PCI0)
    {
        // registers needed for disabling EHC#1
        Scope(EH01)
        {
            OperationRegion(PSTS, PCI_Config, 0x54, 2)
            Field(PSTS, WordAcc, NoLock, Preserve)
            {
                PSTE, 2  // bits 2:0 are power state
            }
        }
        Scope(LPCB)
        {
            OperationRegion(RMLP, PCI_Config, 0xF0, 4)
            Field(RMLP, DWordAcc, NoLock, Preserve)
            {
                RCB1, 32, // Root Complex Base Address
            }
            // address is in bits 31:14
            OperationRegion(FDM1, SystemMemory, Add(And(RCB1,Not(Subtract(ShiftLeft(1,14),1))),0x3418), 4)
            Field(FDM1, DWordAcc, NoLock, Preserve)
            {
                ,15,    // skip first 15 bits
                FDE1,1, // should be bit 15 (0-based) (FD EHCI#1)
            }
        }
        Device(RMD1)
        {
            //Name(_ADR, 0)
            Name(_HID, "RMD10000")
            Method(_INI)
            {
                // disable EHCI#1
                // put EHCI#1 in D3hot (sleep mode)
                Store(3, ^^EH01.PSTE)
                // disable EHCI#1 PCI space
                Store(1, ^^LPCB.FDE1)
            }
        }
    }

//
// For disabling the discrete GPU
//

    External(_SB.PCI0.RP05.PEGP._OFF, MethodObj)
    Device(RMD2)
    {
        Name(_HID, "RMD20000")
        Method(_INI)
        {
            // disable discrete graphics (Nvidia/Radeon) if it is present
            If (CondRefOf(\_SB.PCI0.RP05.PEGP._OFF)) { \_SB.PCI0.RP05.PEGP._OFF() }
        }
    }
    Name(_SB.PCI0.RP05.PXSX._STA, 0)

    // Note other important code in SSDT-DGPU.dsl

    External(_SB.PCI0.LPCB.EC, DeviceObj)
    External(_SB.PCI0.LPCB.EC.NVPR, FieldUnitObj)
    External(_SB.PCI0.LPCB.EC.XREG, MethodObj)

    // Override EC._REG to take care of EC related code removed from HGOF
    Scope(_SB.PCI0.LPCB.EC)
    {
        OperationRegion(ECR3, EmbeddedControl, 0x00, 0xFF)
        // original _REG is renamed to XREG
        Method(_REG, 2)
        {
            // call original _REG (now renamed XREG)
            XREG(Arg0, Arg1)

            If (3 == Arg0 && 1 == Arg1 && CondRefOf(\_SB.PCI0.RP05.PEGP._OFF))
            {
                // original EC related code from HGOF
                Store (Zero, \_SB.PCI0.LPCB.EC.NVPR)
            }
        }
    }


//
// Display backlight implementation
//
// From SSDT-PNLF.dsl
// Adding PNLF device for IntelBacklight.kext or AppleBacklight.kext+AppleBacklightInjector.kext

#define SANDYIVY_PWMMAX 0x710
#define HASWELL_PWMMAX 0xad9
#define SKYLAKE_PWMMAX 0x56c

    External(RMCF.BKLT, IntObj)
    External(RMCF.LMAX, IntObj)

    External(_SB.PCI0.IGPU, DeviceObj)
    Scope(_SB.PCI0.IGPU)
    {
        // need the device-id from PCI_config to inject correct properties
        OperationRegion(IGD5, PCI_Config, 0, 0x14)
    }

    // For backlight control
    Device(_SB.PCI0.IGPU.PNLF)
    {
        Name(_ADR, Zero)
        Name(_HID, EisaId ("APP0002"))
        Name(_CID, "backlight")
        // _UID is set depending on PWMMax
        // 14: Sandy/Ivy 0x710
        // 15: Haswell/Broadwell 0xad9
        // 16: Skylake/KabyLake 0x56c (and some Haswell, example 0xa2e0008)
        // 99: Other
        Name(_UID, 0)
        Name(_STA, 0x0B)

        // IntelBacklight.kext configuration
        Name(RMCF, Package()
        {
            "PWMMax", 0,
        })

        Field(^IGD5, AnyAcc, NoLock, Preserve)
        {
            Offset(0x02), GDID,16,
            Offset(0x10), BAR1,32,
        }

        OperationRegion(RMB1, SystemMemory, BAR1 & ~0xF, 0xe1184)
        Field(RMB1, AnyAcc, Lock, Preserve)
        {
            Offset(0x48250),
            LEV2, 32,
            LEVL, 32,
            Offset(0x70040),
            P0BL, 32,
            Offset(0xc8250),
            LEVW, 32,
            LEVX, 32,
            Offset(0xe1180),
            PCHL, 32,
        }

        Method(_INI)
        {
            // IntelBacklight.kext takes care of this at load time...
            // If RMCF.BKLT does not exist, it is assumed you want to use AppleBacklight.kext...
            If (CondRefOf(\RMCF.BKLT)) { If (1 != \RMCF.BKLT) { Return } }

            // Adjustment required when using AppleBacklight.kext
            Local0 = GDID
            Local2 = Ones
            if (CondRefOf(\RMCF.LMAX)) { Local2 = \RMCF.LMAX }

            If (Ones != Match(Package()
            {
                // Sandy
                0x0116, 0x0126, 0x0112, 0x0122,
                // Ivy
                0x0166, 0x016a,
                // Arrandale
                0x42, 0x46
            }, MEQ, Local0, MTR, 0, 0))
            {
                // Sandy/Ivy
                if (Ones == Local2) { Local2 = SANDYIVY_PWMMAX }

                // change/scale only if different than current...
                Local1 = LEVX >> 16
                If (!Local1) { Local1 = Local2 }
                If (Local2 != Local1)
                {
                    // set new backlight PWMMax but retain current backlight level by scaling
                    Local0 = (LEVL * Local2) / Local1
                    //REVIEW: wait for vblank before setting new PWM config
                    //For (Local7 = P0BL, P0BL == Local7, ) { }
                    Local3 = Local2 << 16
                    If (Local2 > Local1)
                    {
                        // PWMMax is getting larger... store new PWMMax first
                        LEVX = Local3
                        LEVL = Local0
                    }
                    Else
                    {
                        // otherwise, store new brightness level, followed by new PWMMax
                        LEVL = Local0
                        LEVX = Local3
                    }
                }
            }
            Else
            {
                // otherwise... Assume Haswell/Broadwell/Skylake
                if (Ones == Local2)
                {
                    // check Haswell and Broadwell, as they are both 0xad9 (for most common ig-platform-id values)
                    If (Ones != Match(Package()
                    {
                        // Haswell
                        0x0d26, 0x0a26, 0x0d22, 0x0412, 0x0416, 0x0a16, 0x0a1e, 0x0a1e, 0x0a2e, 0x041e, 0x041a,
                        // Broadwell
                        0x0BD1, 0x0BD2, 0x0BD3, 0x1606, 0x160e, 0x1616, 0x161e, 0x1626, 0x1622, 0x1612, 0x162b,
                    }, MEQ, Local0, MTR, 0, 0))
                    {
                        Local2 = HASWELL_PWMMAX
                    }
                    Else
                    {
                        // assume Skylake/KabyLake, both 0x56c
                        // 0x1916, 0x191E, 0x1926, 0x1927, 0x1912, 0x1932, 0x1902, 0x1917, 0x191b,
                        // 0x5916, 0x5912, 0x591b, others...
                        Local2 = SKYLAKE_PWMMAX
                    }
                }

                // This 0xC value comes from looking what OS X initializes this\n
                // register to after display sleep (using ACPIDebug/ACPIPoller)\n
                LEVW = 0xC0000000

                // change/scale only if different than current...
                Local1 = LEVX >> 16
                If (!Local1) { Local1 = Local2 }
                If (Local2 != Local1)
                {
                    // set new backlight PWMAX but retain current backlight level by scaling
                    Local0 = (((LEVX & 0xFFFF) * Local2) / Local1) | (Local2 << 16)
                    //REVIEW: wait for vblank before setting new PWM config
                    //For (Local7 = P0BL, P0BL == Local7, ) { }
                    LEVX = Local0
                }
            }

            // Now Local2 is the new PWMMax, set _UID accordingly
            // The _UID selects the correct entry in AppleBacklightInjector.kext
            If (Local2 == SANDYIVY_PWMMAX) { _UID = 14 }
            ElseIf (Local2 == HASWELL_PWMMAX) { _UID = 15 }
            ElseIf (Local2 == SKYLAKE_PWMMAX) { _UID = 16 }
            Else { _UID = 99 }
        }
    }

//
// Audio configuration
//

    External(_SB.PCI0.HDEF, DeviceObj)
    Name(_SB.PCI0.HDEF.RMCF, Package()
    {
        "CodecCommanderProbeInit", Package()
        {
            "Version", 0x020600,
            "10ec_0283", Package()
            {
                "PinConfigDefault", Package()
                {
                    Package(){},
                    Package()
                    {
                        //"LayoutID", 2,
                        "PinConfigs", Package()
                        {
                            Package(){},
                            0x12, 0x90a00110,
                            0x14, 0x90170140,
                            0x17, 0x400000f0,
                            0x18, 0x400000f0,
                            0x19, 0x400000f0,
                            0x1a, 0x000000f0,
                            0x1b, 0x400000f0,
                            0x1d, 0x400000f0,
                            0x1e, 0x400000f0,
                            0x21, 0x03211050,
                        },
                    },
                },
                "Custom Commands", Package()
                {
                    Package(){},
                    Package()
                    {
                        //"LayoutID", 2,
                        "Command", Buffer()
                        {
                            0x01, 0x47, 0x0c, 0x02,
                            0x02, 0x17, 0x0c, 0x02
                        },
                    },
                },
            },
        },
    })

//
// Standard Injections/Fixes
//

    Scope(_SB.PCI0)
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
                    If (!Arg2) { Return (Buffer() { 0x03 } ) }
                    Return (Package() { "address", 0x57 })
                }
            }
        }

        External(IGPU, DeviceObj)
        Scope(IGPU)
        {
            // need the device-id from PCI_config to inject correct properties
            OperationRegion(RMIG, PCI_Config, 2, 2)
            Field(RMIG, AnyAcc, NoLock, Preserve)
            {
                GDID,16
            }

            // inject properties for integrated graphics on IGPU
            Method(_DSM, 4)
            {
                If (!Arg2) { Return (Buffer() { 0x03 } ) }
                Local1 = Package()
                {
                    "model", Buffer() { "place holder" },
                    "device-id", Buffer() { 0x12, 0x04, 0x00, 0x00 },
                    "hda-gfx", Buffer() { "onboard-1" },
                    "AAPL,ig-platform-id", Buffer() { 0x06, 0x00, 0x26, 0x0a },
                }
                Local0 = GDID
                If (0x0a16 == Local0) { Local1[1] = Buffer() { "Intel HD Graphics 4400" } }
                ElseIf (0x0416 == Local0) { Local1[1] = Buffer() { "Intel HD Graphics 4600" } }
                ElseIf (0x0a1e == Local0) { Local1[1] = Buffer() { "Intel HD Graphics 4200" } }
                Else
                {
                    // others (HD5000 and Iris) are natively supported
                    Local1 = Package()
                    {
                        "hda-gfx", Buffer() { "onboard-1" },
                        "AAPL,ig-platform-id", Buffer() { 0x06, 0x00, 0x26, 0x0a },
                    }
                }
                Return(Local1)
            }
        }
    }

//
// Keyboard/Trackpad
//

    External(_SB.PCI0.LPCB.PS2K, DeviceObj)
    Scope (_SB.PCI0.LPCB.PS2K)
    {
        // Select specific keyboard map in VoodooPS2Keyboard.kext
        Method(_DSM, 4)
        {
            If (!Arg2) { Return (Buffer() { 0x03 } ) }
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
                "DynamicEWMode", ">y",
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
                    "e0fb=6b", // brightness down (was =91)
                    "e0fc=71", // brightness up (was =90)
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

        External(\_SB.PCI0.LPCB.EC.XQ94, MethodObj)

        // RKAB/RKAC called for PS2 code e0fb/e0fc (brightness is mapped to it)
        Method(RKAB, 1)
        {
            // if screen is turned off, turn it on...
            If (LNot(\_SB.PCI0.LPCB.EC.BLIS))
            {
                Store (1, \_SB.PCI0.LPCB.EC.BLIS)
                \_SB.PCI0.LPCB.EC.XQ94()
                \_SB.PCI0.LPCB.EC._Q41()
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
                \_SB.PCI0.LPCB.EC.XQ94()
                \_SB.PCI0.LPCB.EC._Q41()
            }
        }
        Method(RKA1, 1)
        {
            If (Arg0)
            {
                // F9 with keys swapped, do what EC would do (toggle screen)
                Store(LNot(\_SB.PCI0.LPCB.EC.BLIS), \_SB.PCI0.LPCB.EC.BLIS)
                RKA0(Arg0)
            }
        }
        Method(RKA2, 1)
        {
            If (Arg0)
            {
                // Fn+F9 with keys swapped, undo what EC would do (avoid toggling screen)
                Store(LNot(\_SB.PCI0.LPCB.EC.BLIS), \_SB.PCI0.LPCB.EC.BLIS)
            }
        }
    }

    External(_SB.PCI0.LPCB.EC, DeviceObj)
    Scope(_SB.PCI0.LPCB.EC)
    {
        External(TPDS, FieldUnitObj)
        External(\TPVD, FieldUnitObj)
        External(\_SB.PCI0.LPCB.SYVD, IntObj)
        External(\_SB.PCI0.LPCB.ELVD, IntObj)

        // The native _Qxx methods in DSDT are renamed XQxx,
        // so notifications from the EC driver will land here.

        // _Q91 (Fn+F11) called on brightness down key
        Method(_Q91)
        {
            If (LEqual(TPVD, SYVD))
            {
                // Synaptics
                // e06b: code for brightness down
                Notify(\_SB.PCI0.LPCB.PS2K, 0x046b)
            }
            Else
            {
                // Other(ELAN)
                Notify(\_SB.PCI0.LPCB.PS2K, 0x20)
            }
        }
        //_Q90 (Fn+F12) called on brightness up key
        Method(_Q90)
        {
            If (LEqual(TPVD, SYVD))
            {
                // Synaptics
                // e06c: code for brightness up
                Notify(\_SB.PCI0.LPCB.PS2K, 0x046c)
            }
            Else
            {
                // Other(ELAN)
                Notify(\_SB.PCI0.LPCB.PS2K, 0x10)
            }
        }
        Method(_Q94)
        {
            If (LEqual(TPVD, SYVD))
            {
                // Synaptics
                // e069 will be mapped to either F10 (44) or e0f0 or e0f2
                Notify(\_SB.PCI0.LPCB.PS2K, 0x0469)
            }
            // Else not implemented for ELAN
        }
        Method(_Q8F)
        {
            // EC toggles TPDS when this key is struck before arriving here
            // We can cancel the toggle by setting TPDS=1 (trackpad enabled)
            Store(1, TPDS)
            If (LEqual(TPVD, SYVD))
            {
                // Synaptics
                // e066 will be mapped to either F6 (40) or e037
                Notify(\_SB.PCI0.LPCB.PS2K, 0x0466)
            }
            // Else not implemented for ELAN
        }
        Method(_Q41)
        {
            // e067 will be mapped to either F7 (41) or itself
            //Notify(\_SB.PCI0.LPCB.PS2K, 0x0467)
        }
    }

//
// Battery Status
//

    // Override for ACPIBatteryManager.kext
    External(_SB.BAT1, DeviceObj)
    Name(_SB.BAT1.RMCF, Package()
    {
        "StartupDelay", 10,
    })

    Scope(_SB.PCI0.LPCB.EC)
    {
        External(BLIS, FieldUnitObj)
        External(ECOK, IntObj)
        External(RTMP, FieldUnitObj)

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
        External(WAEC, MethodObj)
        External(WADR, MethodObj)
        External(CREC, MethodObj)
        External(HIID, FieldUnitObj)

        // UPBI and UPBS in DSDT are renamed to XPBI and XPBS.  As a result,
        // calls from _BST, _BIF land here, where we can deal with
        // OS X limitations regarding EC fields larger than 8-bit

        Method (\_SB.BAT1.UPBI, 0, NotSerialized)
        {
            Acquire (BATM, 0xFFFF)
            Store (Zero, Index (PBIF, Zero))
            Multiply (B1B2 (^^PCI0.LPCB.EC.B1F0, ^^PCI0.LPCB.EC.B1F1), 0x0A, Index (PBIF, 0x02))
            ^^PCI0.LPCB.EC.WAEC ()
            Store (0x02, ^^PCI0.LPCB.EC.HIID)
            ^^PCI0.LPCB.EC.WADR ()
            Multiply (B1B2 (^^PCI0.LPCB.EC.DIC0, ^^PCI0.LPCB.EC.DIC1), 0x0A, Local1)
            Store (Local1, Index (PBIF, One))
            Store (B1B2 (^^PCI0.LPCB.EC.DIV0, ^^PCI0.LPCB.EC.DIV1), Index (PBIF, 0x04))
            ^^PCI0.LPCB.EC.CREC ()
            Store (Divide (Local1, 0x0A, ), Index (PBIF, 0x05))
            Store (Divide (Multiply (Local1, 0x02), 0x64, ), Index (PBIF, 0x06))
            ^^PCI0.LPCB.EC.WAEC ()
            Store (0x06, ^^PCI0.LPCB.EC.HIID)
            ^^PCI0.LPCB.EC.WADR ()
            Store (^^PCI0.LPCB.EC.RDDN(), Index (PBIF, 0x09))
            ^^PCI0.LPCB.EC.CREC ()
            Store ("LION", Index (PBIF, 0x0B))
            ^^PCI0.LPCB.EC.WAEC ()
            Store (0x05, ^^PCI0.LPCB.EC.HIID)
            ^^PCI0.LPCB.EC.WADR ()
            Store (^^PCI0.LPCB.EC.RDMN(), Index (PBIF, 0x0C))
            ^^PCI0.LPCB.EC.CREC ()
            Release (BATM)
        }
        
        External(\_SB.POSW, MethodObj)
        External(\_SB.BAT1.PBST, PkgObj)
        External(MBTF, FieldUnitObj)
        External(MBWC, FieldUnitObj)
        External(MBDS, FieldUnitObj)

        Method (\_SB.BAT1.UPBS, 0, NotSerialized)
        {
            Store (B1B2 (^^PCI0.LPCB.EC.MCU0, ^^PCI0.LPCB.EC.MCU1), Local5)
            Multiply (POSW (Local5), 0x0A, Index (PBST, One))
            Multiply (B1B2 (^^PCI0.LPCB.EC.MBR0, ^^PCI0.LPCB.EC.MBR1), 0x0A, Index (PBST, 0x02))
            Store (B1B2 (^^PCI0.LPCB.EC.MBV0, ^^PCI0.LPCB.EC.MBV1), Index (PBST, 0x03))
            If (^^PCI0.LPCB.EC.MBTF)
            {
                Store (Zero, Index (PBST, Zero))
            }
            Else
            {
                If (LNotEqual (Local5, Zero))
                {
                    If (^^PCI0.LPCB.EC.MBWC)
                    {
                        Store (0x02, Index (PBST, Zero))
                    }
                    Else
                    {
                        If (^^PCI0.LPCB.EC.MBDS)
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
                    If (^^PCI0.LPCB.EC.MBWC)
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
}
// EOF
