// TODO: header stuff

// Custom operand types

// TODO: move into M6502 namespace?
def brtarget : Operand<OtherVT>;
def call_target : Operand<iPTR>;
def imm_addr : Operand<i16>; // FIXME: is this needed?

// Custom type profiles

def SDT_M6502FIAddr : SDTypeProfile<1, 2, [SDTCisVT<0, i16>,
                                           SDTCisVT<1, i16>,
                                           SDTCisVT<2, i16>]>;
def SDT_M6502Shift1 : SDTypeProfile<1, 1, [SDTCisVT<0, i8>, SDTCisVT<1, i8>]>;
def SDT_M6502BrInd : SDTypeProfile<0, 1, [SDTCisVT<0, OtherVT>]>;

def SDT_M6502Call : SDTypeProfile<0, -1, [SDTCisVT<0, iPTR>]>;
def SDT_M6502Cmp : SDTypeProfile<0, 2, [SDTCisVT<0, i8>, SDTCisVT<1, i8>]>;
// BSet and BClear parameters: Flag, Branch Target
def SDT_M6502BSet : SDTypeProfile<0, 2,
                                  [SDTCisVT<0, OtherVT>, SDTCisVT<1, OtherVT>]>;
def SDT_M6502BClear : SDTypeProfile<0, 2,
                                    [SDTCisVT<0, OtherVT>, SDTCisVT<1, OtherVT>]>;
def SDT_M6502SelectCC : SDTypeProfile<1, 3, [SDTCisVT<0, i8>, SDTCisVT<1, i8>,
                                             SDTCisVT<2, i8>, SDTCisVT<3, i8>]>;
def SDT_M6502Flag : SDTypeProfile<1, 0, [SDTCisVT<0, OtherVT>]>;

// Custom nodes

// Address nodes
def M6502fiaddr : SDNode<"M6502ISD::FIADDR", SDT_M6502FIAddr>;

// Shift 1 nodes
def M6502asl1 : SDNode<"M6502ISD::ASL1", SDT_M6502Shift1,
                       [SDNPOutGlue]>;
def M6502rol1 : SDNode<"M6502ISD::ROL1", SDT_M6502Shift1,
                       [SDNPOutGlue, SDNPInGlue]>;

// Indirect branch nodes
def M6502brind : SDNode<"M6502ISD::BRIND", SDT_M6502BrInd,
                        [SDNPHasChain]>;


// Call-related nodes
def M6502call : SDNode<"M6502ISD::CALL", SDT_M6502Call,
                       [SDNPHasChain, SDNPOutGlue, SDNPInGlue, SDNPVariadic]>;
def M6502return : SDNode<"M6502ISD::RETURN", SDTNone,
                         [SDNPHasChain, SDNPOptInGlue, SDNPVariadic]>;

// Comparison and conditional branching nodes
def M6502cmp : SDNode<"M6502ISD::CMP", SDT_M6502Cmp, [SDNPOutGlue]>;
def M6502bset : SDNode<"M6502ISD::BSET", SDT_M6502BSet,
                       [SDNPHasChain, SDNPInGlue, SDNPOutGlue]>;
def M6502bclear : SDNode<"M6502ISD::BCLEAR", SDT_M6502BClear,
                         [SDNPHasChain, SDNPInGlue, SDNPOutGlue]>;
def M6502selectcc : SDNode<"M6502ISD::SELECT_CC", SDT_M6502SelectCC,
                           [SDNPInGlue]>;

// Flag nodes for bset and bclear
def M6502nflag : SDNode<"M6502ISD::NFLAG", SDT_M6502Flag, []>; // negative
def M6502zflag : SDNode<"M6502ISD::ZFLAG", SDT_M6502Flag, []>; // zero
def M6502cflag : SDNode<"M6502ISD::CFLAG", SDT_M6502Flag, []>; // carry
def M6502vflag : SDNode<"M6502ISD::VFLAG", SDT_M6502Flag, []>; // overflow

// Instructions

class I : Instruction {
  let Namespace = "M6502";
  let isPseudo = 1; // XXX: for now, all instructions are pseudo-instructions.
}

// TODO: Add Defs and Uses for Flag registers in instructions that modify flags

multiclass AccOperatorI<string AsmName, SDPatternOperator Oper> {
  // Immediate
  def _imm : I {
    let OutOperandList = (outs GPR8:$ao);
    let InOperandList = (ins GPR8:$ai, i8imm:$x);
    let Constraints = "$ao = $ai";
    let AsmString = AsmName # "_imm $ai, $x";
    let Pattern = [(set GPR8:$ao, (Oper GPR8:$ai, imm:$x))];
  }

  // Address in Pointer register
  def _ptr : I {
    let OutOperandList = (outs GPR8:$ao);
    let isCommutable = 0; // XXX: operands might break isCommutable rule. FIXME: is this needed?
    let InOperandList = (ins GPR8:$ai, DREGS:$p);
    let Constraints = "$ao = $ai";
    let AsmString = AsmName # "_ptr $ai, $p";
    let Pattern = [(set GPR8:$ao, (Oper GPR8:$ai, (load DREGS:$p)))];
    let mayLoad = 1;
  }

  // Operand in memory register
  def _mem : I {
    let OutOperandList = (outs GPR8:$ao);
    let InOperandList = (ins GPR8:$ai, GPR8:$m);
    let Constraints = "$ao = $ai";
    let AsmString = AsmName # "_mem $ai, $m";
    let Pattern = [(set GPR8:$ao, (Oper GPR8:$ai, GPR8:$m))];
  }

  // 16-bit pseudoinstructions
  def _16_imm : I {
    let OutOperandList = (outs DREGS:$po);
    let InOperandList = (ins DREGS:$pi, i16imm:$x);
    let Constraints = "$po = $pi";
    let AsmString = AsmName # "_16_imm $pi, $x";
    let Pattern = [(set DREGS:$po, (Oper DREGS:$pi, imm:$x))];
  }

  def _16 : I {
    let OutOperandList = (outs DREGS:$po);
    let InOperandList = (ins DREGS:$pi, DREGS:$rhs);
    let Constraints = "$po = $pi";
    let AsmString = AsmName # "_16 $pi, $rhs";
    let Pattern = [(set DREGS:$po, (Oper DREGS:$pi, DREGS:$rhs))];
  }
  // TODO: Register
  // TODO: Absolute address
}

// XXX: Fake "AD0" instruction should generate:
//      CLC
//      ADC ...
let isCommutable = 1, Defs = [NF, ZF, CF, VF] in
  defm AD0 : AccOperatorI<"AD0", addc>;
let isCommutable = 1, Defs = [NF, ZF, CF, VF], Uses = [CF] in
  defm ADC : AccOperatorI<"ADC", adde>;

// XXX: Fake instruction for regular add
// TODO: delete
let isCommutable = 1, Defs = [NF, ZF, CF, VF] in
  defm ADD : AccOperatorI<"ADD", add>;

// XXX: Fake "SB1" instruction should generate:
//      SEC
//      SBC ...
let Defs = [NF, ZF, CF, VF] in
  defm SB1 : AccOperatorI<"SB1", subc>;
let Defs = [NF, ZF, CF, VF], Uses = [CF] in
  defm SBC : AccOperatorI<"SBC", sube>;

// XXX: Fake instruction for regular sub
// TODO: delete
let Defs = [NF, ZF, CF, VF] in
  defm SUB : AccOperatorI<"SUB", sub>;

let isCommutable = 1, Defs = [NF, ZF] in
  defm AND : AccOperatorI<"AND", and>;
let isCommutable = 1, Defs = [NF, ZF] in
  defm EOR : AccOperatorI<"EOR", xor>;
let isCommutable = 1, Defs = [NF, ZF] in
  defm ORA : AccOperatorI<"ORA", or>;

// Shift left by immediate amount
// FIXME: This is not a real instruction in 6502. The closest equivalent is
// ASL, which shifts A left by one bit.
def ASL_imm : I {
  let Defs = [NF, ZF, CF];
  let OutOperandList = (outs GPR8:$ao);
  let InOperandList = (ins GPR8:$ai, i8imm:$x);
  let Constraints = "$ao = $ai";
  let AsmString = "ASL_imm $ai, $x";
  let Pattern = [(set GPR8:$ao, (shl GPR8:$ai, (i8 imm:$x)))];
}

// Arithmetic shift right
// FIXME: This is not a real instruction in 6502. This instruction must be
// expanded to CMP's and ROR's. For example, see
// <https://wiki.nesdev.com/w/index.php/6502_assembly_optimisations#Arithmetic_shift_right>
def ASR_imm : I {
  let Defs = [NF, ZF, CF];
  let OutOperandList = (outs GPR8:$ao);
  let InOperandList = (ins GPR8:$ai, i8imm:$x);
  let Constraints = "$ao = $ai";
  let AsmString = "ASR_imm $ai, $x";
  let Pattern = [(set GPR8:$ao, (sra GPR8:$ai, (i8 imm:$x)))];
}

// Logical shift right
// FIXME: This is not a real instruction in 6502. The closest equivalent is
// LSR, which shifts A right by one bit.
def LSR_imm : I {
  let Defs = [ZF, CF];
  let OutOperandList = (outs GPR8:$ao);
  let InOperandList = (ins GPR8:$ai, i8imm:$x);
  let Constraints = "$ao = $ai";
  let AsmString = "LSR_imm $ai, $x";
  let Pattern = [(set GPR8:$ao, (srl GPR8:$ai, (i8 imm:$x)))];
}

// Shift left one bit, move highest bit to CF
// TODO: memory operands
def ASL_1 : I {
  let Defs = [NF, ZF, CF];
  let OutOperandList = (outs GPR8:$ao);
  let InOperandList = (ins GPR8:$ai);
  let Constraints = "$ao = $ai";
  let AsmString = "ASL $ai";
  let Pattern = [(set GPR8:$ao, (M6502asl1 GPR8:$ai))];
}

// Rotate left one bit through CF
// TODO: memory operands
def ROL_1 : I {
  let Defs = [NF, ZF, CF];
  let Uses = [CF];
  let OutOperandList = (outs GPR8:$ao);
  let InOperandList = (ins GPR8:$ai);
  let Constraints = "$ao = $ai";
  let AsmString = "ROL $ai";
  let Pattern = [(set GPR8:$ao, (M6502rol1 GPR8:$ai))];
}

// Branch on flag instructions
multiclass CondBranchI<SDPatternOperator Flag, string IfSetName,
                       string IfClearName> {
  def _set : I {
    let OutOperandList = (outs);
    let InOperandList = (ins brtarget:$target);
    let AsmString = IfSetName # " $target";
    let Pattern = [(M6502bset (Flag), bb:$target)];
    let isBranch = 1;
    let isTerminator = 1;
  }

  def _clear : I {
    let OutOperandList = (outs);
    let InOperandList = (ins brtarget:$target);
    let AsmString = IfClearName # " $target";
    let Pattern = [(M6502bclear (Flag), bb:$target)];
    let isBranch = 1;
    let isTerminator = 1;
  }
}

let Uses = [NF] in
  defm BN : CondBranchI<M6502nflag, "BMI", "BPL">;
let Uses = [ZF] in
  defm BZ : CondBranchI<M6502zflag, "BEQ", "BNE">;
let Uses = [CF] in
  defm BC : CondBranchI<M6502cflag, "BCS", "BCC">;
let Uses = [VF] in
  defm BV : CondBranchI<M6502vflag, "BVS", "BVC">;

let usesCustomInserter = 1 in {
  // NOTE: Custom inserter converts SELECT to conditional branches
  // TODO: add Flag node operand to select instructions
  // FIXME: restrict to physregs
  def SELECT : I {
    let OutOperandList = (outs GPR8:$r);
    let InOperandList = (ins GPR8:$a, GPR8:$b, i8imm:$cc);
    let AsmString = "SELECT $a, $b, $cc # Pseudo";
    let Pattern = [(set GPR8:$r, (M6502selectcc GPR8:$a, GPR8:$b,
                                                   imm:$cc))];
  }
}

// Compare Register with Immediate
// TODO: Define CMP with a multiclass like AccOperatorI
// NOTE: 6502 has CMP instructions for all registers (CMP, CPX, CPY). However,
// only the first one has indexed addressing modes.
def CMP_imm : I {
  let Defs = [NF, ZF, CF];
  let OutOperandList = (outs);
  let InOperandList = (ins GPR8:$ai, i8imm:$x);
  let AsmString = "CMP_imm $ai, $x";
  let Pattern = [(M6502cmp GPR8:$ai, imm:$x)];
}

// TODO: CMP_abs, etc.

// Jump
def JMP_abs : I {
  let OutOperandList = (outs);
  let InOperandList = (ins brtarget:$target);
  let AsmString = "JMP $target";
  let Pattern = [(br bb:$target)];
  let isBranch = 1; // This is a branch instruction
  let isTerminator = 1; // This instruction is part of the terminator for a basic block
  let isBarrier = 1; // Control flow cannot fall through this instruction
}

// DEX, DEY
// TODO: DEC instruction: decrement memory by one
def DE_reg : I {
  let Defs = [NF, ZF];
  let OutOperandList = (outs GPR8:$io);
  let InOperandList = (ins GPR8:$ii);
  let Constraints = "$io = $ii";
  let AsmString = "DE_reg $ii";
  let Pattern = [(set GPR8:$io, (sub GPR8:$ii, 1))];
}

// INX, INY
// TODO: INC instruction: increment memory by one
def IN_reg : I {
  let Defs = [NF, ZF];
  let OutOperandList = (outs GPR8:$io);
  let InOperandList = (ins GPR8:$ii);
  let Constraints = "$io = $ii";
  let AsmString = "IN_reg $ii";
  let Pattern = [(set GPR8:$io, (add GPR8:$ii, 1))];
}

let isMoveImm = 1, isAsCheapAsAMove = 1, isReMaterializable = 1 in {
// LDA, LDX, LDY
def LD_imm : I {
  let Defs = [NF, ZF];
  let OutOperandList = (outs GPR8:$r);
  let InOperandList = (ins i8imm:$x);
  let AsmString = "LD_imm $r, $x";
  let Pattern = [(set GPR8:$r, (i8 imm:$x))];
}

} // isMoveImm = 1, isAsCheapAsAMove = 1, isReMaterializable = 1

// Load from absolute address
def LD_abs : I {
  let Defs = [NF, ZF];
  let OutOperandList = (outs GPR8:$r);
  let InOperandList = (ins imm_addr:$addr); // FIXME: Declare imm16 type as in AVRInstrInfo.td?
  let AsmString = "LD_abs $r, $addr";
  let Pattern = [(set GPR8:$r, (load imm:$addr))];
  let mayLoad = 1;
  let canFoldAsLoad = 1;
}

def LD_abs_16 : I {
  let OutOperandList = (outs DREGS:$r);
  let InOperandList = (ins imm_addr:$addr);
  let AsmString = "LD_abs_16 $r, $addr";
  let Pattern = [(set DREGS:$r, (load imm:$addr))];
  let mayLoad = 1;
}

// Load from stack
def LD_stack : I {
  let OutOperandList = (outs GPR8:$r);
  let InOperandList = (ins i16imm:$fi, i16imm:$offs);
  let AsmString = "LD_stack $r, [$fi]+$offs";
  let Pattern = [(set GPR8:$r, (load (M6502fiaddr tframeindex:$fi, imm:$offs)))];
  let mayLoad = 1;
}

def LD_stack_16 : I {
  let OutOperandList = (outs DREGS:$r);
  let InOperandList = (ins i16imm:$fi, i16imm:$offs);
  let AsmString = "LD_stack_16 $r, [$fi]+$offs";
  let Pattern = [(set DREGS:$r, (load (M6502fiaddr tframeindex:$fi, imm:$offs)))];
  let mayLoad = 1;
}

// Load from address in Pointer register
def LD_ptr : I {
  let OutOperandList = (outs GPR8:$r);
  let InOperandList = (ins DREGS:$p);
  let AsmString = "LD_ptr $r, $p";
  let Pattern = [(set GPR8:$r, (load DREGS:$p))];
  let mayLoad = 1;
}

// Set Pointer register
def LD_addr : I {
  let OutOperandList = (outs DREGS:$p);
  let InOperandList = (ins i16imm:$addr);
  let AsmString = "LD_addr $p, $addr";
  let Pattern = [(set DREGS:$p, imm:$addr)];
}

def : Pat<(i16 (tglobaladdr:$addr)),
          (LD_addr tglobaladdr:$addr)>;

// Set Pointer register to address of stack object
def LD_stack_addr : I {
  let OutOperandList = (outs DREGS:$p);
  let InOperandList = (ins i16imm:$fi, i16imm:$offs);
  let AsmString = "LD_stack_addr $p, [$fi]+$offs";
  let Pattern = [(set DREGS:$p, (M6502fiaddr tframeindex:$fi, imm:$offs))];
}

def : Pat<(i16 (M6502fiaddr tframeindex:$fi, imm:$offs)),
          (LD_stack_addr tframeindex:$fi, imm:$offs)>;

def LD_ptr_reg : I {
  let OutOperandList = (outs DREGS:$p);
  let InOperandList = (ins i16imm:$addr);
  let AsmString = "LD_ptr_reg $p, $addr";
  let Pattern = [(set DREGS:$p, (load imm:$addr))];
  let mayLoad = 1;
}

// Store to stack
def ST_stack : I {
  let OutOperandList = (outs);
  let InOperandList = (ins GPR8:$r, i16imm:$fi, i16imm:$offs);
  let AsmString = "ST_stack $r, [$fi]+$offs";
  let Pattern = [(store GPR8:$r, (M6502fiaddr tframeindex:$fi, imm:$offs))];
  let mayStore = 1;
}

// Store 16-bit value to stack
def ST_stack_16 : I {
  let OutOperandList = (outs);
  let InOperandList = (ins DREGS:$p, i16imm:$fi, i16imm:$offs);
  let AsmString = "ST_stack_16 $p, [$fi]+$offs";
  let Pattern = [(store DREGS:$p, (M6502fiaddr tframeindex:$fi, imm:$offs))];
  let mayStore = 1;
}

// Store to address in Pointer registers
def ST_ptr : I {
  let OutOperandList = (outs);
  let InOperandList = (ins GPR8:$r, DREGS:$p);
  let AsmString = "ST_ptr $r, $p";
  let Pattern = [(store GPR8:$r, DREGS:$p)];
  let mayStore = 1;
}

// Store to absolute address
def ST_abs : I {
  let OutOperandList = (outs);
  let InOperandList = (ins GPR8:$r, i16imm:$addr);
  let AsmString = "ST_abs $r, $addr";
  let Pattern = [(store GPR8:$r, imm:$addr)];
  let mayStore = 1;
}

def ST_abs_16 : I {
  let OutOperandList = (outs);
  let InOperandList = (ins DREGS:$r, i16imm:$addr);
  let AsmString = "ST_abs_16 $r, $addr";
  let Pattern = [(store DREGS:$r, imm:$addr)];
  let mayStore = 1;
}

def LSR_1 : I {
  let Defs = [ZF, CF];
  let OutOperandList = (outs GPR8:$ao);
  let InOperandList = (ins GPR8:$ai);
  let Constraints = "$ao = $ai";
  let AsmString = "LSR $ai";
  let Pattern = [(set GPR8:$ao, (srl GPR8:$ai, (i8 1)))];
}

// Sign- and zero-extend operations
def SEXT : I {
  let OutOperandList = (outs DREGS:$dst);
  let InOperandList = (ins GPR8:$src);
  let AsmString = "SEXT $src, $dst";
  let Pattern = [(set DREGS:$dst, (sext GPR8:$src))];
}

def ZEXT : I {
  let OutOperandList = (outs DREGS:$dst);
  let InOperandList = (ins GPR8:$src);
  let AsmString = "ZEXT $src, $dst";
  let Pattern = [(set DREGS:$dst, (zext GPR8:$src))];
}

// `anyext`
def : Pat<(i16 (anyext i8:$src)),
          (INSERT_SUBREG (i16 (IMPLICIT_DEF)), i8:$src, sub_lo)>;

// Generic call instruction
// The actual instructions generated depend on the calling convention. (TODO)
def CALL_imm : I {
  let isCall = 1; // This is a call instruction
  let OutOperandList = (outs);
  let InOperandList = (ins call_target:$target);
  let AsmString = "CALL $target";
  let Pattern = [(M6502call imm:$target)];
}

def : Pat<(M6502call (i16 tglobaladdr:$dst)),
          (CALL_imm tglobaladdr:$dst)>;

// Generic return instruction
// This should emit RTS or JMP depending on the calling convention. (TODO)
def RETURN : I {
  let isReturn = 1; // This is a return instruction
  let isTerminator = 1; // This instruction is part of the terminator for a basic block
  let isBarrier = 1; // Control flow cannot fall through this instruction
  let OutOperandList = (outs);
  let InOperandList = (ins);
  let Pattern = [(M6502return)];
  let AsmString = "RETURN";
}

// TAX, TAY, TXA, TYA (may compile as memory loads/stores)
// TODO: Transfer instructions may modify flags!
// FIXME: 6502 has a limited set of register-to-register transfer instructions.
// X and Y cannot be transferred directly between themselves; neither can Mem
// registers.
def T_reg : I {
  let Defs = [NF, ZF];
  let OutOperandList = (outs GPR8:$dst);
  let InOperandList = (ins GPR8:$src);
  let AsmString = "T_reg $dst, $src";
  let Pattern = [];
  // NOTE: This instruction is generated by copyPhysReg.
  // Do NOT attempt to use the pattern below! If the pattern below is
  // uncommented, LLVM will mistakenly use T_reg as a "catch-all" for patterns
  // that have no other matches, leading to output like:
  //   T_reg R0, R0
  // if no other instruction that assigns the correct value to R0 can be found.
  //let Pattern = [(set GPR8:$dst, GPR8:$src)];
}
