from riscv_assembler.convert import AssemblyConverter

cnv = AssemblyConverter(output_type = "t")
cnv.convert("simple.s")
