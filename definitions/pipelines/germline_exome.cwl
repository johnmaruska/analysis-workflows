#!/usr/bin/env cwl-runner

cwlVersion: v1.0
class: Workflow
label: "exome alignment and germline variant detection"
requirements:
    - class: SchemaDefRequirement
      types:
          - $import: ../types/labelled_file.yml
          - $import: ../types/sequence_data.yml
          - $import: ../types/trimming_options.yml
          - $import: ../types/vep_custom_annotation.yml
    - class: SubworkflowFeatureRequirement
inputs:
    reference:
        type:
            - string
            - File
        secondaryFiles: [.fai, ^.dict, .amb, .ann, .bwt, .pac, .sa]
    sequence:
        type: ../types/sequence_data.yml#sequence_data[]
        label: "sequence: sequencing data and readgroup information"
        doc: |
          sequence represents the sequencing data as either FASTQs or BAMs with accompanying
          readgroup information. Note that in the @RG field ID and SM are required.
    trimming:
        type:
            - ../types/trimming_options.yml#trimming_options
            - "null"
    bqsr_known_sites:
        type: File[]
        secondaryFiles: [.tbi]
        doc: "One or more databases of known polymorphic sites used to exclude regions around known polymorphisms from analysis."
    bqsr_intervals:
        type: string[]?
    bait_intervals:
        type: File
        label: "bait_intervals: interval_list file of baits used in the sequencing experiment"
        doc: |
          bait_intervals is an interval_list corresponding to the baits used in sequencing reagent.
          These are essentially coordinates for regions you were able to design probes for in the reagent.
          Typically the reagent provider has this information available in bed format and it can be
          converted to an interval_list with Picard BedToIntervalList. Astrazeneca also maintains a repo
          of baits for common sequencing reagents available at https://github.com/AstraZeneca-NGS/reference_data
    target_intervals:
        type: File
        label: "target_intervals: interval_list file of targets used in the sequencing experiment"
        doc: |
          target_intervals is an interval_list corresponding to the targets for the capture reagent.
          Bed files with this information can be converted to interval_lists with Picard BedToIntervalList.
          In general for a WES exome reagent bait_intervals and target_intervals are the same.
    target_interval_padding:
        type: int
        label: "target_interval_padding: number of bp flanking each target region in which to allow variant calls"
        doc: |
            The effective coverage of capture products generally extends out beyond the actual regions
            targeted. This parameter allows variants to be called in these wingspan regions, extending
            this many base pairs from each side of the target regions.
        default: 100
    per_base_intervals:
        type: ../types/labelled_file.yml#labelled_file[]
    per_target_intervals:
        type: ../types/labelled_file.yml#labelled_file[]
    summary_intervals:
        type: ../types/labelled_file.yml#labelled_file[]
    omni_vcf:
        type: File
        secondaryFiles: [.tbi]
    picard_metric_accumulation_level:
        type: string
    gvcf_gq_bands:
        type: string[]
    intervals:
        type:
            type: array
            items:
                type: array
                items: string
    ploidy:
        type: int?
    vep_cache_dir:
        type:
            - string
            - Directory
    vep_ensembl_assembly:
        type: string
        doc: "genome assembly to use in vep. Examples: GRCh38 or GRCm38"
    vep_ensembl_version:
        type: string
        doc: "ensembl version - Must be present in the cache directory. Example: 95"
    vep_ensembl_species:
        type: string
        doc: "ensembl species - Must be present in the cache directory. Examples: homo_sapiens or mus_musculus"
    vep_plugins:
        type: string[]?
        doc: "array of plugins to use when running vep"
    synonyms_file:
        type: File?
    annotate_coding_only:
        type: boolean?
    qc_minimum_mapping_quality:
        type: int?
    qc_minimum_base_quality:
        type: int?
    vep_custom_annotations:
        type: ../types/vep_custom_annotation.yml#vep_custom_annotation[]
        doc: "custom type, check types directory for input format"
    variants_to_table_fields:
         type: string[]?
    variants_to_table_genotype_fields:
         type: string[]?
    vep_to_table_fields:
         type: string[]?
outputs:
    cram:
        type: File
        outputSource: index_cram/indexed_cram
    mark_duplicates_metrics:
        type: File
        outputSource: alignment_and_qc/mark_duplicates_metrics
    insert_size_metrics:
        type: File
        outputSource: alignment_and_qc/insert_size_metrics
    insert_size_histogram:
        type: File
        outputSource: alignment_and_qc/insert_size_histogram
    alignment_summary_metrics:
        type: File
        outputSource: alignment_and_qc/alignment_summary_metrics
    hs_metrics:
        type: File
        outputSource: alignment_and_qc/hs_metrics
    per_target_coverage_metrics:
        type: File[]
        outputSource: alignment_and_qc/per_target_coverage_metrics
    per_target_hs_metrics:
        type: File[]
        outputSource: alignment_and_qc/per_target_hs_metrics
    per_base_coverage_metrics:
        type: File[]
        outputSource: alignment_and_qc/per_base_coverage_metrics
    per_base_hs_metrics:
        type: File[]
        outputSource: alignment_and_qc/per_base_hs_metrics
    summary_hs_metrics:
        type: File[]
        outputSource: alignment_and_qc/summary_hs_metrics
    flagstats:
        type: File
        outputSource: alignment_and_qc/flagstats
    verify_bam_id_metrics:
        type: File
        outputSource: alignment_and_qc/verify_bam_id_metrics
    verify_bam_id_depth:
        type: File
        outputSource: alignment_and_qc/verify_bam_id_depth
    raw_vcf:
        type: File
        outputSource: detect_variants/raw_vcf
        secondaryFiles: [.tbi]
    final_vcf:
        type: File
        outputSource: detect_variants/final_vcf
        secondaryFiles: [.tbi]
    filtered_vcf:
        type: File
        outputSource: detect_variants/filtered_vcf
        secondaryFiles: [.tbi]
    vep_summary:
        type: File
        outputSource: detect_variants/vep_summary
    final_tsv:
       type: File
       outputSource: detect_variants/final_tsv
    filtered_tsv:
       type: File
       outputSource: detect_variants/filtered_tsv
steps:
    alignment_and_qc:
        run: alignment_exome.cwl
        in:
            reference: reference
            sequence: sequence
            trimming: trimming
            bqsr_known_sites: bqsr_known_sites
            bqsr_intervals: bqsr_intervals
            bait_intervals: bait_intervals
            target_intervals: target_intervals
            per_base_intervals: per_base_intervals
            per_target_intervals: per_target_intervals
            summary_intervals: summary_intervals
            omni_vcf: omni_vcf
            picard_metric_accumulation_level: picard_metric_accumulation_level   
            qc_minimum_mapping_quality: qc_minimum_mapping_quality
            qc_minimum_base_quality: qc_minimum_base_quality
        out:
            [bam, mark_duplicates_metrics, insert_size_metrics, insert_size_histogram, alignment_summary_metrics, hs_metrics, per_target_coverage_metrics, per_target_hs_metrics, per_base_coverage_metrics, per_base_hs_metrics, summary_hs_metrics, flagstats, verify_bam_id_metrics, verify_bam_id_depth]
    extract_freemix:
        in:
            verify_bam_id_metrics: alignment_and_qc/verify_bam_id_metrics
        out:
            [freemix_score]
        run:
            class: ExpressionTool
            requirements:
                - class: InlineJavascriptRequirement
            inputs:
                verify_bam_id_metrics:
                    type: File
                    inputBinding:
                        loadContents: true
            outputs:
                freemix_score:
                    type: string?
            expression: |
                        ${
                            var metrics = inputs.verify_bam_id_metrics.contents.split("\n");
                            if ( metrics[0].split("\t")[6] == 'FREEMIX' ) {
                                return {'freemix_score': metrics[1].split("\t")[6]};
                            } else {
                                return {'freemix_score:': null };
                            }
                        }
    pad_target_intervals:
        run: ../tools/interval_list_expand.cwl
        in:
            interval_list: target_intervals
            roi_padding: target_interval_padding
        out:
            [expanded_interval_list]
    detect_variants:
        run: ../subworkflows/germline_detect_variants.cwl
        in:
            reference: reference
            bam: alignment_and_qc/bam
            gvcf_gq_bands: gvcf_gq_bands
            intervals: intervals
            ploidy: ploidy
            contamination_fraction: extract_freemix/freemix_score
            vep_cache_dir: vep_cache_dir
            synonyms_file: synonyms_file
            annotate_coding_only: annotate_coding_only
            limit_variant_intervals: pad_target_intervals/expanded_interval_list
            vep_ensembl_assembly: vep_ensembl_assembly
            vep_ensembl_version: vep_ensembl_version
            vep_ensembl_species: vep_ensembl_species
            vep_plugins: vep_plugins
            vep_to_table_fields: vep_to_table_fields
            vep_custom_annotations: vep_custom_annotations
            variants_to_table_fields: variants_to_table_fields
            variants_to_table_genotype_fields: variants_to_table_genotype_fields
        out:
            [raw_vcf, final_vcf, filtered_vcf, vep_summary, final_tsv, filtered_tsv]
    bam_to_cram:
        run: ../tools/bam_to_cram.cwl
        in:
            bam: alignment_and_qc/bam
            reference: reference
        out:
            [cram]
    index_cram:
         run: ../tools/index_cram.cwl
         in:
            cram: bam_to_cram/cram
         out:
            [indexed_cram]
