// TODO: header stuff

class M6502Reg<string name, list<Register> subregs = []> :
  RegisterWithSubRegs<name, subregs>
{
  let Namespace = "M6502";
}

//===----------------------------------------------------------------------===//
// Registers
//===----------------------------------------------------------------------===//

// 8-bit general purpose registers located in Z-page memory
def R0 : M6502Reg<"r0">;
def R1 : M6502Reg<"r1">;
def R2 : M6502Reg<"r2">;
def R3 : M6502Reg<"r3">;

// Subregister indices (inspired by the AVR target)
let Namespace = "M6502" in
{
  def sub_lo : SubRegIndex<8>;
  def sub_hi : SubRegIndex<8, 8>;
}

let SubRegIndices = [sub_lo, sub_hi],
CoveredBySubRegs = 1 in
{
  def R3R2 : M6502Reg<"r3:r2", [R2, R3]>;
  def R1R0 : M6502Reg<"r1:r0", [R0, R1]>;
}

// Flag registers. These registers serve to coordinate Uses and Defs of
// instructions that modify or accept flags, such as CMP and BEQ.
def NF : M6502Reg<"NF">; // negative flag
def ZF : M6502Reg<"ZF">; // zero flag
def CF : M6502Reg<"CF">; // carry flag
def VF : M6502Reg<"VF">; // overflow flag

//===----------------------------------------------------------------------===//
//  Register classes
//===----------------------------------------------------------------------===//

def GPR8 : RegisterClass<"M6502", [i8], 8,
  (add R0, R1, R2, R3)>;
def DREGS : RegisterClass<"M6502", [i16], 8,
  (add R1R0, R3R2)>;
