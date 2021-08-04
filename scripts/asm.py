import sys
from riscv_assembler.convert import AssemblyConverter

if __name__ == '__main__':
  cnv = AssemblyConverter(output_type = "t")
  if len(sys.argv) < 2:
    print("Provide the path of RV assembly code")
    sys.exit(0)
  cnv.convert(sys.argv[1])
