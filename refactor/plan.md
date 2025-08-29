# Speaker Diarization Refactoring Plan

## Overview
Enhance the Deepgram transcription system to support speaker diarization when converting to SRT format, while maintaining backward compatibility and following Ruby best practices.

## Analysis Summary

### Current Architecture
- **DeepgramConvertAction**: Orchestrates conversion process
- **DeepgramParser**: Extracts data from Deepgram JSON responses
- **DeepgramFormatter**: Converts parsed data to various formats
- Clean three-layer architecture with good separation of concerns

### Speaker Diarization Data Available
The Deepgram API response includes speaker information in the `words` array:
- `speaker`: integer (speaker ID, e.g., 0, 1, 2)
- `speaker_confidence`: float (confidence score for speaker identification)
- Word-level timestamps: `start` and `end` times

### Current Limitations
- No extraction of speaker data from words array
- Paragraph-based segmentation doesn't account for speaker changes
- No configuration options for speaker-related settings

## Refactoring Tasks

### ✅ Completed
- [x] Analyzed current code structure
- [x] Identified speaker diarization requirements
- [x] Selected optimal AI agents for implementation

### 🔄 Phase 1: Configuration Enhancement (Priority: HIGH)
**Agent**: `configuration-expert`
**Status**: Pending
**Files to modify**:
- `lib/ComputerTools/config/deepgram.yml`

**Tasks**:
- [ ] Extend deepgram.yml with speaker diarization configuration section
- [ ] Add configuration schema for speaker options:
  - `enable`: boolean to enable speaker diarization
  - `confidence_threshold`: minimum confidence score (default: 0.8)
  - `label_format`: speaker label format (default: "[Speaker %d]: ")
  - `merge_consecutive_segments`: merge same-speaker segments (default: true)
  - `min_segment_duration`: minimum segment duration in seconds (default: 1.0)
- [ ] Add configuration validation logic

**Expected Output**: Enhanced configuration with speaker diarization options

### 🔄 Phase 2: Parser Extensions (Priority: HIGH)
**Agent**: `ruby-pro`
**Status**: Pending
**Files to modify**:
- `lib/ComputerTools/wrappers/deepgram_parser.rb`

**Tasks**:
- [ ] Add `words_with_speaker_info` method to extract speaker data
- [ ] Implement `speaker_segments` method to group words by speaker
- [ ] Add `has_speaker_data?` method to check for speaker information availability
- [ ] Handle confidence threshold filtering
- [ ] Add speaker-related summary statistics
- [ ] Ensure graceful handling of missing speaker data

**Expected Output**: Enhanced parser with speaker data extraction capabilities

### 🔄 Phase 3: Formatter Enhancements (Priority: HIGH)
**Agent**: `ruby-pro`
**Status**: Pending
**Files to modify**:
- `lib/ComputerTools/wrappers/deepgram_formatter.rb`

**Tasks**:
- [ ] Modify `to_srt` method to accept optional speaker configuration
- [ ] Implement `build_srt_with_speakers` private method
- [ ] Add speaker label formatting logic
- [ ] Handle speaker segment timing and transitions
- [ ] Maintain backward compatibility with existing paragraph-based SRT
- [ ] Add proper SRT timestamp formatting for speaker segments

**Expected Output**: Enhanced formatter with speaker-aware SRT generation

### 🔄 Phase 4: Action Coordination (Priority: MEDIUM)
**Agent**: `ruby-pro`
**Status**: Pending
**Files to modify**:
- `lib/ComputerTools/actions/deepgram/deepgram_convert_action.rb`

**Tasks**:
- [ ] Add speaker configuration loading logic
- [ ] Pass speaker options to formatter
- [ ] Add speaker-specific validation and error handling
- [ ] Update format-specific success messages for speaker-enabled SRT
- [ ] Ensure graceful fallback when speaker data is unavailable

**Expected Output**: Enhanced action with speaker configuration support

### 🔄 Phase 5: Testing Suite (Priority: HIGH)
**Agent**: `test-automator`
**Status**: Pending
**Files to create/modify**:
- `spec/wrappers/deepgram_parser_spec.rb` (new tests)
- `spec/wrappers/deepgram_formatter_spec.rb` (new tests)  
- `spec/actions/deepgram/deepgram_convert_action_spec.rb` (new tests)

**Tasks**:
- [ ] Create unit tests for speaker data extraction methods
- [ ] Test speaker segment generation with various confidence thresholds
- [ ] Test SRT generation with speaker information
- [ ] Test configuration loading and validation
- [ ] Test backward compatibility (no speaker data scenarios)
- [ ] Test error handling and edge cases
- [ ] Create integration tests for end-to-end functionality
- [ ] Achieve 90%+ test coverage for new features

**Expected Output**: Comprehensive test suite for speaker diarization features

### 🔄 Phase 6: Code Review (Priority: MEDIUM)
**Agent**: `code-reviewer-pro`
**Status**: Pending
**Files to review**: All modified files

**Tasks**:
- [ ] Review code for Ruby best practices
- [ ] Validate architectural consistency
- [ ] Check for performance optimizations
- [ ] Ensure proper error handling
- [ ] Validate test coverage and quality
- [ ] Suggest improvements for maintainability

**Expected Output**: Code quality validation and improvement recommendations

### 🔄 Phase 7: Documentation Updates (Priority: MEDIUM)
**Agent**: `documentation-expert`
**Status**: Pending
**Files to modify**:
- `lib/ComputerTools/wrappers/deepgram_parser.rb` (YARD docs)
- `lib/ComputerTools/wrappers/deepgram_formatter.rb` (YARD docs)
- `lib/ComputerTools/actions/deepgram/deepgram_convert_action.rb` (YARD docs)
- `lib/ComputerTools/config/deepgram.yml` (comments)

**Tasks**:
- [ ] Update YARD documentation for new methods
- [ ] Add comprehensive usage examples
- [ ] Document new configuration options
- [ ] Create speaker diarization feature documentation
- [ ] Update method signatures and parameter documentation
- [ ] Add code examples for speaker-enabled SRT generation

**Expected Output**: Updated documentation with speaker diarization feature coverage

## Implementation Strategy

### Approach: **Extend Existing Classes**
- Maintain backward compatibility
- Follow Open/Closed Principle
- Preserve existing API contracts
- Allow gradual adoption of speaker features

### Key Design Principles
1. **Configuration-Driven**: Speaker features are opt-in via configuration
2. **Graceful Degradation**: Falls back to paragraph-based SRT when speaker data unavailable
3. **Confidence Thresholds**: Configurable speaker confidence filtering
4. **Ruby Idioms**: Clean, readable, maintainable Ruby code
5. **Test Coverage**: Comprehensive testing for reliability

### Speaker Segmentation Algorithm
1. Extract words with speaker data from JSON response
2. Apply confidence threshold filtering
3. Group consecutive words by same speaker ID
4. Merge short segments from same speaker (configurable)
5. Generate SRT entries with speaker labels

### Error Handling Strategy
- Graceful degradation when speaker data is malformed
- Meaningful error messages for configuration issues
- Fallback to paragraph-based SRT when speaker processing fails
- Logging for debugging speaker diarization issues

## Success Criteria
- ✅ Speaker diarization configuration system implemented
- ✅ Speaker data extraction from Deepgram API responses
- ✅ Speaker-aware SRT generation with configurable labels
- ✅ Backward compatibility maintained
- ✅ 90%+ test coverage for new functionality
- ✅ Comprehensive documentation updated
- ✅ Code review passed with Ruby best practices

## Risk Assessment

### Low Risk
- Configuration extension (additive)
- New parser methods (non-breaking)
- Documentation updates

### Medium Risk  
- Formatter modifications (complex logic)
- Speaker segmentation algorithm
- Test coverage completeness

### High Risk
- Action coordination changes (integration point)
- Backward compatibility maintenance
- Performance impact of new features

## Rollback Strategy
- Git checkpoints before each phase
- Feature flags for speaker diarization
- Incremental testing and validation
- Quick disable via configuration

---

**Session Started**: 2025-08-29
**Last Updated**: 2025-08-29  
**Status**: Planning Complete - Ready for Implementation