#!/usr/bin/env cwl-runner

cwlVersion: v1.0
class: Workflow
label: "wgs alignment and somatic variant detection"
requirements:
    - class: SchemaDefRequirement
      types:
          - $import: ../types/labelled_file.yml
          - $import: ../types/sequence_data.yml
          - $import: ../types/trimming_options.yml
    - class: MultipleInputFeatureRequirement
    - class: SubworkflowFeatureRequirement
    - class: StepInputExpressionRequirement
inputs:
    reference:
        type:
            - string
            - File
        secondaryFiles: [.fai, ^.dict, .amb, .ann, .bwt, .pac, .sa]
    tumor_sequence:
        type: ../types/sequence_data.yml#sequence_data[]
        label: "tumor_sequence: MT sequencing data and readgroup information"
        doc: |
          tumor_sequence represents the sequencing data for the MT sample as either FASTQs or BAMs with
          accompanying readgroup information. Note that in the @RG field ID and SM are required.
    tumor_name:
        type: string?
        default: 'tumor'
        label: "tumor_name: String specifying the name of the MT sample"
        doc: |
          tumor_name provides a string for what the MT sample will be referred to in the various
          outputs, for example the VCF files.
    normal_sequence:
        type: ../types/sequence_data.yml#sequence_data[]
        label: "normal_sequence: WT sequencing data and readgroup information"
        doc: |
          normal_sequence represents the sequencing data for the WT sample as either FASTQs or BAMs with
          accompanying readgroup information. Note that in the @RG field ID and SM are required.
    normal_name:
        type: string?
        default: 'normal'
        label: "normal_name: String specifying the name of the WT sample"
        doc: |
          normal_name provides a string for what the WT sample will be referred to in the various
          outputs, for example the VCF files.
    trimming:
        type:
            - ../types/trimming_options.yml#trimming_options
            - "null"
    target_intervals:
        type: File
    per_base_intervals:
        type: ../types/labelled_file.yml#labelled_file[]
    per_target_intervals:
        type: ../types/labelled_file.yml#labelled_file[]
    summary_intervals:
        type: ../types/labelled_file.yml#labelled_file[]
    picard_metric_accumulation_level:
        type: string
    qc_minimum_mapping_quality:
        type: int?
        default: 0
    qc_minimum_base_quality:
        type: int?
        default: 0
    strelka_cpu_reserved:
        type: int?
        default: 8
    scatter_count:
        type: int
        doc: "scatters each supported variant detector (varscan, mutect) into this many parallel jobs"
    varscan_strand_filter:
        type: int?
        default: 0
    varscan_min_coverage:
        type: int?
        default: 8
    varscan_min_var_freq:
        type: float?
        default: 0.05
    varscan_p_value:
        type: float?
        default: 0.99
    varscan_max_normal_freq:
        type: float?
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
    synonyms_file:
        type: File?
    annotate_coding_only:
        type: boolean?
    vep_pick:
        type:
            - "null"
            - type: enum
              symbols: ["pick", "flag_pick", "pick_allele", "per_gene", "pick_allele_gene", "flag_pick_allele", "flag_pick_allele_gene"]
    cle_vcf_filter:
        type: boolean
        default: false
    filter_somatic_llr_threshold:
        type: float
        default: 5
        doc: "Sets the stringency (log-likelihood ratio) used to filter out non-somatic variants.  Typical values are 10=high stringency, 5=normal, 3=low stringency. Low stringency may be desirable when read depths are low (as in WGS)"
    filter_somatic_llr_tumor_purity:
        type: float
        default: 1
        doc: "Sets the purity of the tumor used in the somatic llr filter, used to remove non-somatic variants. Probably only needs to be adjusted for low-purity (< 50%).  Range is 0 to 1"
    filter_somatic_llr_normal_contamination_rate:
        type: float
        default: 0
        doc: "Sets the fraction of tumor present in the normal sample (range 0 to 1), used in the somatic llr filter. Useful for heavily contaminated adjacent normals. Range is 0 to 1"
    variants_to_table_fields:
        type: string[]
        default: [CHROM,POS,ID,REF,ALT,set,AC,AF]
    variants_to_table_genotype_fields:
        type: string[]
        default: [GT,AD]
    vep_to_table_fields:
        type: string[]
        default: ['Consequence','SYMBOL','Feature']
    tumor_sample_name:
        type: string
    normal_sample_name:
        type: string
    cnvkit_target_average_size:
        type: int?
        doc: "approximate size of split target bins for CNVkit; if not set a suitable window size will be set by CNVkit automatically"
    manta_non_wgs:
        type: boolean?
        default: false
    manta_output_contigs:
        type: boolean?
outputs:
    tumor_cram:
        type: File
        outputSource: tumor_index_cram/indexed_cram
    tumor_mark_duplicates_metrics:
        type: File
        outputSource: tumor_alignment_and_qc/mark_duplicates_metrics
    tumor_insert_size_metrics:
        type: File
        outputSource: tumor_alignment_and_qc/insert_size_metrics
    tumor_alignment_summary_metrics:
        type: File
        outputSource: tumor_alignment_and_qc/alignment_summary_metrics
    tumor_per_target_coverage_metrics:
        type: File[]
        outputSource: tumor_alignment_and_qc/per_target_coverage_metrics
    tumor_per_target_hs_metrics:
        type: File[]
        outputSource: tumor_alignment_and_qc/per_target_hs_metrics
    tumor_per_base_coverage_metrics:
        type: File[]
        outputSource: tumor_alignment_and_qc/per_base_coverage_metrics
    tumor_per_base_hs_metrics:
        type: File[]
        outputSource: tumor_alignment_and_qc/per_base_hs_metrics
    tumor_summary_hs_metrics:
        type: File[]
        outputSource: tumor_alignment_and_qc/summary_hs_metrics
    tumor_flagstats:
        type: File
        outputSource: tumor_alignment_and_qc/flagstats
    normal_cram:
        type: File
        outputSource: normal_index_cram/indexed_cram
    normal_mark_duplicates_metrics:
        type: File
        outputSource: normal_alignment_and_qc/mark_duplicates_metrics
    normal_insert_size_metrics:
        type: File
        outputSource: normal_alignment_and_qc/insert_size_metrics
    normal_alignment_summary_metrics:
        type: File
        outputSource: normal_alignment_and_qc/alignment_summary_metrics
    normal_per_target_coverage_metrics:
        type: File[]
        outputSource: normal_alignment_and_qc/per_target_coverage_metrics
    normal_per_target_hs_metrics:
        type: File[]
        outputSource: normal_alignment_and_qc/per_target_hs_metrics
    normal_per_base_coverage_metrics:
        type: File[]
        outputSource: normal_alignment_and_qc/per_base_coverage_metrics
    normal_per_base_hs_metrics:
        type: File[]
        outputSource: normal_alignment_and_qc/per_base_hs_metrics
    normal_summary_hs_metrics:
        type: File[]
        outputSource: normal_alignment_and_qc/summary_hs_metrics
    normal_flagstats:
        type: File
        outputSource: normal_alignment_and_qc/flagstats
    mutect_unfiltered_vcf:
        type: File
        outputSource: detect_variants/mutect_unfiltered_vcf
        secondaryFiles: [.tbi]
    mutect_filtered_vcf:
        type: File
        outputSource: detect_variants/mutect_filtered_vcf
        secondaryFiles: [.tbi]
    strelka_unfiltered_vcf:
        type: File
        outputSource: detect_variants/strelka_unfiltered_vcf
        secondaryFiles: [.tbi]
    strelka_filtered_vcf:
        type: File
        outputSource: detect_variants/strelka_filtered_vcf
        secondaryFiles: [.tbi]
    varscan_unfiltered_vcf:
        type: File
        outputSource: detect_variants/varscan_unfiltered_vcf
        secondaryFiles: [.tbi]
    varscan_filtered_vcf:
        type: File
        outputSource: detect_variants/varscan_filtered_vcf
        secondaryFiles: [.tbi]
    final_vcf:
        type: File
        outputSource: detect_variants/final_vcf
        secondaryFiles: [.tbi]
    final_filtered_vcf:
        type: File
        outputSource: detect_variants/final_filtered_vcf
        secondaryFiles: [.tbi]
    final_tsv:
        type: File
        outputSource: detect_variants/final_tsv
    vep_summary:
        type: File
        outputSource: detect_variants/vep_summary
    tumor_snv_bam_readcount_tsv:
        type: File
        outputSource: detect_variants/tumor_snv_bam_readcount_tsv
    tumor_indel_bam_readcount_tsv:
        type: File
        outputSource: detect_variants/tumor_indel_bam_readcount_tsv
    normal_snv_bam_readcount_tsv:
        type: File
        outputSource: detect_variants/normal_snv_bam_readcount_tsv
    normal_indel_bam_readcount_tsv:
        type: File
        outputSource: detect_variants/normal_indel_bam_readcount_tsv
    cnvkit_intervals_antitarget:
        type: File
        outputSource: cnvkit/intervals_antitarget
    cnvkit_intervals_target:
        type: File
        outputSource: cnvkit/intervals_target
    cnvkit_normal_antitarget_coverage:
        type: File
        outputSource: cnvkit/normal_antitarget_coverage
    cnvkit_normal_target_coverage:
        type: File
        outputSource: cnvkit/normal_target_coverage
    cnvkit_reference_coverage:
        type: File
        outputSource: cnvkit/reference_coverage
    cnvkit_cn_diagram:
        type: File
        outputSource: cnvkit/cn_diagram
    cnvkit_cn_scatter_plot:
        type: File
        outputSource: cnvkit/cn_scatter_plot
    cnvkit_tumor_antitarget_coverage:
        type: File
        outputSource: cnvkit/tumor_antitarget_coverage
    cnvkit_tumor_target_coverage:
        type: File
        outputSource: cnvkit/tumor_target_coverage
    cnvkit_tumor_bin_level_ratios:
        type: File
        outputSource: cnvkit/tumor_bin_level_ratios
    cnvkit_tumor_segmented_ratios:
        type: File
        outputSource: cnvkit/tumor_segmented_ratios
    diploid_variants:
        type: File?
        outputSource: manta/diploid_variants
        secondaryFiles: [.tbi]
    somatic_variants:
        type: File?
        outputSource: manta/somatic_variants
        secondaryFiles: [.tbi]
    all_candidates:
        type: File
        outputSource: manta/all_candidates
        secondaryFiles: [.tbi]
    small_candidates:
        type: File
        outputSource: manta/small_candidates
        secondaryFiles: [.tbi]
    tumor_only_variants:
        type: File?
        outputSource: manta/tumor_only_variants
        secondaryFiles: [.tbi]
steps:
    tumor_alignment_and_qc:
        run: alignment_wgs_nonhuman.cwl
        in:
            reference: reference
            sequence: tumor_sequence
            trimming: trimming
            per_base_intervals: per_base_intervals
            per_target_intervals: per_target_intervals
            summary_intervals: summary_intervals
            picard_metric_accumulation_level: picard_metric_accumulation_level   
            qc_minimum_mapping_quality: qc_minimum_mapping_quality
            qc_minimum_base_quality: qc_minimum_base_quality
            final_name:
                source: tumor_name
                valueFrom: "$(self).bam"
        out:
            [alignment_summary_metrics, bam, bamcoverage_bigwig, flagstats, gc_bias_metrics, gc_bias_metrics_chart, gc_bias_metrics_summary, insert_size_histogram, insert_size_metrics, mark_duplicates_metrics, per_base_coverage_metrics, per_base_hs_metrics, per_target_coverage_metrics, per_target_hs_metrics, summary_hs_metrics, wgs_metrics]
    normal_alignment_and_qc:
        run: alignment_wgs_nonhuman.cwl
        in:
            reference: reference
            sequence: normal_sequence
            trimming: trimming
            per_base_intervals: per_base_intervals
            per_target_intervals: per_target_intervals
            summary_intervals: summary_intervals
            picard_metric_accumulation_level: picard_metric_accumulation_level   
            qc_minimum_mapping_quality: qc_minimum_mapping_quality
            qc_minimum_base_quality: qc_minimum_base_quality
            final_name:
                source: normal_name
                valueFrom: "$(self).bam"
        out:
            [alignment_summary_metrics, bam, bamcoverage_bigwig, flagstats, gc_bias_metrics, gc_bias_metrics_chart, gc_bias_metrics_summary, insert_size_histogram, insert_size_metrics, mark_duplicates_metrics, per_base_coverage_metrics, per_base_hs_metrics, per_target_coverage_metrics, per_target_hs_metrics, summary_hs_metrics, wgs_metrics]
    detect_variants:
        run: detect_variants_wgs_nonhuman.cwl
        in:
            reference: reference
            tumor_bam: tumor_alignment_and_qc/bam
            normal_bam: normal_alignment_and_qc/bam
            roi_intervals: target_intervals
            strelka_exome_mode:
                default: false
            strelka_cpu_reserved: strelka_cpu_reserved
            scatter_count: scatter_count
            varscan_strand_filter: varscan_strand_filter
            varscan_min_coverage: varscan_min_coverage
            varscan_min_var_freq: varscan_min_var_freq
            varscan_p_value: varscan_p_value
            varscan_max_normal_freq: varscan_max_normal_freq
            vep_cache_dir: vep_cache_dir
            synonyms_file: synonyms_file
            annotate_coding_only: annotate_coding_only
            vep_pick: vep_pick
            cle_vcf_filter: cle_vcf_filter
            filter_somatic_llr_threshold: filter_somatic_llr_threshold
            filter_somatic_llr_tumor_purity: filter_somatic_llr_tumor_purity
            filter_somatic_llr_normal_contamination_rate: filter_somatic_llr_normal_contamination_rate
            variants_to_table_fields: variants_to_table_fields
            variants_to_table_genotype_fields: variants_to_table_genotype_fields
            vep_ensembl_assembly: vep_ensembl_assembly
            vep_ensembl_version: vep_ensembl_version
            vep_ensembl_species: vep_ensembl_species
            vep_to_table_fields: vep_to_table_fields
            tumor_sample_name: tumor_sample_name
            normal_sample_name: normal_sample_name
        out:
            [mutect_unfiltered_vcf, mutect_filtered_vcf, strelka_unfiltered_vcf, strelka_filtered_vcf, varscan_unfiltered_vcf, varscan_filtered_vcf, final_vcf, final_filtered_vcf, final_tsv, vep_summary, tumor_snv_bam_readcount_tsv, tumor_indel_bam_readcount_tsv, normal_snv_bam_readcount_tsv, normal_indel_bam_readcount_tsv]
    cnvkit:
        run: ../tools/cnvkit_batch.cwl
        in:
            tumor_bam: tumor_alignment_and_qc/bam
            method:
                default: 'wgs'
            reference:
                source: [normal_alignment_and_qc/bam, reference]
                valueFrom: |
                    ${
                      var normal = self[0];
                      var fasta = self[1];
                      return {'normal_bam': normal, 'fasta_file': fasta};
                    }
            target_average_size: cnvkit_target_average_size
        out:
            [intervals_antitarget, intervals_target, normal_antitarget_coverage, normal_target_coverage, reference_coverage, cn_diagram, cn_scatter_plot, tumor_antitarget_coverage, tumor_target_coverage, tumor_bin_level_ratios, tumor_segmented_ratios]
    manta: 
        run: ../tools/manta_somatic.cwl
        in:
            normal_bam: normal_alignment_and_qc/bam
            tumor_bam: tumor_alignment_and_qc/bam
            reference: reference
            non_wgs: manta_non_wgs
            output_contigs: manta_output_contigs
        out:
            [diploid_variants, somatic_variants, all_candidates, small_candidates, tumor_only_variants]
    tumor_bam_to_cram:
        run: ../tools/bam_to_cram.cwl
        in:
            bam: tumor_alignment_and_qc/bam
            reference: reference
        out:
            [cram]
    tumor_index_cram:
         run: ../tools/index_cram.cwl
         in:
            cram: tumor_bam_to_cram/cram
         out:
            [indexed_cram]
    normal_bam_to_cram:
        run: ../tools/bam_to_cram.cwl
        in:
            bam: normal_alignment_and_qc/bam
            reference: reference
        out:
            [cram]
    normal_index_cram:
         run: ../tools/index_cram.cwl
         in:
            cram: normal_bam_to_cram/cram
         out:
            [indexed_cram]

