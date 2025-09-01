# Sublayer → ruby_llm Migration Refactoring Plan

## 🎯 Project Overview

**Objective**: Migrate ComputerTools from Sublayer framework to ruby_llm + ruby_llm-schema ecosystem

**Session ID**: `sublayer_to_ruby_llm_migration_2025_09_01`  
**Status**: 🟡 **ACTIVE**  
**Current Phase**: Phase 1 - Setup and Analysis  
**Progress**: 0/47 tasks completed (0%)

## 📊 Migration Scope

### Components Requiring Migration

#### Actions (13 classes)
- `DeepgramConvertAction`, `DeepgramConfigAction`, `DeepgramAnalyzeAction`, `DeepgramParseAction`
- `FFmpegAction`, `LatestChangesAction`, `UntrackedAnalysisAction`
- `GitAnalysisAction`, `FileDiscoveryAction`, `YadmAnalysisAction`
- `ExampleAction`, `DisplayAvailableModelsAction`, `RunShellCommand`

#### Generators (5 classes)
- `OverviewGenerator`, `FileActivityReportGenerator`
- `DeepgramInsightsGenerator`, `DeepgramTopicsGenerator`, `DeepgramSummaryGenerator`

#### Agents (1 class)
- `ExampleAgent`

#### Providers (2 classes)
- `Ollama`, `OpenRouter`

## 🏗️ Detailed Implementation Plan

### Phase 1: Setup and Analysis ⏳ [0/5 tasks]
**Risk Level**: Low | **Duration**: 30 minutes

- [ ] **Task 1.1**: Create git checkpoint for safe rollback
- [ ] **Task 1.2**: Document current Sublayer usage patterns
- [ ] **Task 1.3**: Analyze dependency requirements for ruby_llm
- [ ] **Task 1.4**: Map class inheritance hierarchies
- [ ] **Task 1.5**: Validate existing ruby_llm gems are available

### Phase 2: Dependencies Migration 🔄 [0/4 tasks]  
**Risk Level**: Low | **Duration**: 20 minutes

- [ ] **Task 2.1**: Remove `sublayer ~> 0.2.9` from gemspec
- [ ] **Task 2.2**: Verify `ruby_llm`, `ruby_llm-schema` dependencies in Gemfile
- [ ] **Task 2.3**: Update main require statements in `lib/ComputerTools.rb`
- [ ] **Task 2.4**: Run bundle install and verify clean dependencies

### Phase 3: Configuration Migration 🔧 [0/6 tasks]
**Risk Level**: Medium | **Duration**: 45 minutes

- [ ] **Task 3.1**: Rename `config/sublayer.yml` to `config/ruby_llm.yml`
- [ ] **Task 3.2**: Update YAML configuration structure for ruby_llm
- [ ] **Task 3.3**: Refactor `lib/ComputerTools/config.rb` for ruby_llm configuration loading
- [ ] **Task 3.4**: Replace `Sublayer::Logging::JsonLogger` with ruby_llm logging
- [ ] **Task 3.5**: Update AI provider configuration patterns
- [ ] **Task 3.6**: Test configuration loading functionality

### Phase 4: Provider Migration 🌐 [0/4 tasks]
**Risk Level**: High | **Duration**: 60 minutes

- [ ] **Task 4.1**: Create new `lib/ComputerTools/providers/ruby_llm/` directory
- [ ] **Task 4.2**: Migrate Ollama provider to ruby_llm patterns
- [ ] **Task 4.3**: Migrate OpenRouter provider to ruby_llm patterns  
- [ ] **Task 4.4**: Update provider registration and loading

### Phase 5: Base Class Migration 📐 [0/6 tasks]
**Risk Level**: High | **Duration**: 90 minutes

- [ ] **Task 5.1**: Create `ComputerTools::Actions::Base` using ruby_llm patterns
- [ ] **Task 5.2**: Create `ComputerTools::Generators::Base` with schema support
- [ ] **Task 5.3**: Create `ComputerTools::Agents::Base` for agent functionality
- [ ] **Task 5.4**: Implement schema conversion utilities for output adapters
- [ ] **Task 5.5**: Create compatibility layer for existing method signatures
- [ ] **Task 5.6**: Test base class functionality independently

### Phase 6: Component Migration 🔄 [0/18 tasks]
**Risk Level**: Medium-High | **Duration**: 120 minutes

#### Actions Migration [0/13 tasks]
- [ ] **Task 6.1**: Migrate `ExampleAction` (test case)
- [ ] **Task 6.2**: Migrate `RunShellCommand`
- [ ] **Task 6.3**: Migrate `DisplayAvailableModelsAction`
- [ ] **Task 6.4**: Migrate `DeepgramConvertAction`
- [ ] **Task 6.5**: Migrate `DeepgramConfigAction`
- [ ] **Task 6.6**: Migrate `DeepgramAnalyzeAction`
- [ ] **Task 6.7**: Migrate `DeepgramParseAction`
- [ ] **Task 6.8**: Migrate `FFmpegAction`
- [ ] **Task 6.9**: Migrate `LatestChangesAction`
- [ ] **Task 6.10**: Migrate `UntrackedAnalysisAction`
- [ ] **Task 6.11**: Migrate `GitAnalysisAction`
- [ ] **Task 6.12**: Migrate `FileDiscoveryAction`
- [ ] **Task 6.13**: Migrate `YadmAnalysisAction`

#### Generators Migration [0/5 tasks]
- [ ] **Task 6.14**: Migrate `OverviewGenerator` with schema conversion
- [ ] **Task 6.15**: Migrate `FileActivityReportGenerator` with schema conversion
- [ ] **Task 6.16**: Migrate `DeepgramInsightsGenerator` with schema conversion
- [ ] **Task 6.17**: Migrate `DeepgramTopicsGenerator` with schema conversion
- [ ] **Task 6.18**: Migrate `DeepgramSummaryGenerator` with schema conversion

### Phase 7: Testing and Validation 🧪 [0/3 tasks]
**Risk Level**: Medium | **Duration**: 45 minutes

- [ ] **Task 7.1**: Update existing specs for new base classes
- [ ] **Task 7.2**: Create integration tests for ruby_llm functionality
- [ ] **Task 7.3**: Run full test suite and fix any failures

### Phase 8: Final Integration 🎉 [0/1 tasks]
**Risk Level**: Low | **Duration**: 15 minutes

- [ ] **Task 8.1**: Final integration testing and documentation updates

## 🔄 Architecture Changes

### Key Pattern Migrations

#### 1. Class Inheritance
```ruby
# OLD (Sublayer)
class MyAction < Sublayer::Actions::Base
end

# NEW (ruby_llm)
class MyAction < ComputerTools::Actions::Base
  include RubyLLM::Tool
end
```

#### 2. Output Adapters → Schemas  
```ruby
# OLD (Sublayer)
llm_output_adapter type: :single_string, name: "summary", description: "..."

# NEW (ruby_llm-schema)
def output_schema
  RubyLLM::Schema.create do
    string :summary, description: "...", required: true
  end
end
```

#### 3. Configuration Loading
```ruby
# OLD (Sublayer)
Sublayer.configure do |c|
  c.ai_provider = Sublayer::Providers::OpenAI
  c.ai_model = "gpt-4"
end

# NEW (ruby_llm)
RubyLLM.configure do |c|
  c.provider = :openai
  c.model = "gpt-4"
end
```

## 🛡️ Risk Mitigation Strategies

### High-Risk Areas
1. **Provider Implementations**: Complex HTTP communication logic
2. **Configuration Loading**: AI model and provider selection
3. **Output Adapter Migration**: Schema definition conversion

### Mitigation Approaches
1. **Git Checkpoints**: Create commits at each phase completion
2. **Incremental Testing**: Validate functionality after each component migration
3. **Backward Compatibility**: Maintain existing public APIs where possible
4. **Rollback Plan**: Clear rollback strategy if critical issues arise

## 📈 Success Metrics

### Quality Targets
- **Test Coverage**: Maintain 90%+ coverage
- **Functionality**: 100% feature parity with existing system
- **Performance**: No performance degradation
- **Code Quality**: Improved maintainability and readability

### Validation Criteria
- [ ] All existing tests pass with new implementation
- [ ] LLM interactions work correctly with all providers
- [ ] Configuration loading functions properly
- [ ] No breaking changes to public APIs
- [ ] Documentation updated to reflect new patterns

## 🔗 Dependencies and Prerequisites

### Required Gems (Already Available)
- `ruby_llm` - Core LLM abstraction library
- `ruby_llm-schema` - Schema definition DSL
- `ruby_llm-mcp` - Rails integration (if needed)

### Git Safety Requirements
- Clean working directory before starting
- Feature branch for migration work
- Regular commits at logical checkpoints

## 📝 Progress Tracking

**Last Updated**: 2025-09-01 00:00:00 UTC  
**Current Focus**: Phase 1 - Setup and Analysis  
**Next Checkpoint**: Complete Phase 1 tasks  

---

**🎯 Ready to Begin**: All prerequisites analyzed, plan documented, session state initialized  
**📋 Next Action**: Create git checkpoint and start Phase 1 execution