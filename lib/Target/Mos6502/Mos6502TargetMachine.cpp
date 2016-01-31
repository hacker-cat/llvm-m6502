// TODO: license stuff

#include "Mos6502TargetMachine.h"
#include "Mos6502.h"
#include "llvm/CodeGen/Passes.h"
#include "llvm/Support/TargetRegistry.h"
#include "llvm/ADT/StringRef.h"
using namespace llvm;

namespace llvm {
extern Target TheMos6502Target;
}

extern "C" void LLVMInitializeMos6502Target() {
  RegisterTargetMachine<Mos6502TargetMachine> X(TheMos6502Target);
}

Mos6502TargetMachine::Mos6502TargetMachine(const Target &T, const Triple &TT,
                                           StringRef CPU, StringRef FS,
                                           const TargetOptions &Options,
                                           Reloc::Model RM, CodeModel::Model CM,
                                           CodeGenOpt::Level OL)
    : LLVMTargetMachine(T, "e-p:16:8", TT, CPU, FS, Options, RM, CM, OL),
      TLOF(std::make_unique<Mos6502TargetObjectFile>()),
      Subtarget(TT, CPU, FS, *this) {

  initAsmInfo();
}

namespace {
class Mos6502PassConfig : public TargetPassConfig {
public:
  Mos6502PassConfig(Mos6502TargetMachine *TM, PassManagerBase &PM)
    : TargetPassConfig(TM, PM) {}

  Mos6502TargetMachine &getMos6502TargetMachine() const {
    return getTM<Mos6502TargetMachine>();
  }

  bool addInstSelector() override;
};
} // namespace

TargetPassConfig *Mos6502TargetMachine::createPassConfig(PassManagerBase &PM) {
  return new Mos6502PassConfig(this, PM);
}

bool Mos6502PassConfig::addInstSelector() {
  addPass(createMos6502ISelDag(getMos6502TargetMachine(), getOptLevel()));
  return false;
}
