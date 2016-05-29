// generated from: ../codec.git/gen_ahhcd.sh ALC283
DefinitionBlock ("", "SSDT", 1, "hack", "ALC283", 0)
{
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
                        "LayoutID", 3,
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
                        "LayoutID", 3,
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
}
//EOF
