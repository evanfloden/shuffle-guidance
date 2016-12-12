
/* 
 * Main shuffle-guidance pipeline script
 *
 * @authors
 * Maria Chatzou
 * Cedric Notredame <cedric.notredame@gmail.com>
 * Evan Floden <evanfloden@gmail.com> 
 */

params.name             = "tutorial_data"
params.seq              = "$baseDir/tutorial/tips16_0.5_001.0400.fa"
params.ref              = "$baseDir/tutorial/tips16_asymmetric_0.5.unroot.tree"
params.output           = "$baseDir/results/"
params.shuffles         = 100
params.shuffle_seed     = 42
params.run_mode         = 'HoT'
params.aligner          = "MAFFT"

log.info "s h u f f l e  -  g u i d a n c e  ~  version 0.1"
log.info "====================================="
log.info "name                            : ${params.name}"
log.info "input sequence (FASTA)          : ${params.seq}"
log.info "reference alignment (ALN)       : ${params.ref}"
log.info "output (DIRECTORY)              : ${params.output}"
log.info "shuffles                        : ${params.shuffles}"
log.info "shuffle seed                    : ${params.shuffle_seed}"
log.info "mode                            : ${params.run_mode}"
log.info "aligner [CLUSTALW|MAFFT|PRANK]  : ${params.aligner}"
log.info "\n"


/**************************
 * 
 * S E T U P   I N P U T S   A N D   P A R A M E T E R S
 *
 */

    shuffle_num             = params.shuffles as int
    seed                    = params.shuffle_seed as int

/*
 * Create a channel for input sequence files & the reference tree
 */

Channel
    .fromPath( params.seq )
    .ifEmpty { error "Cannot find any input sequence files matching: ${params.seq}" }
    .map { file -> tuple( file.baseName, file ) }
    .into { datasetsA; datasetsB ; datasetsC ;}

/* Channel
 *   .fromPath ( params.ref )
 *   .ifEmpty { error "Cannot find any ref sequence files matching: ${params.ref}" }
 *   .map { file -> tuple( file.baseName, file ) }
 *   .set { refAlns }
 */

/*
 * Select method to generate MSA replicates:
 *
 * 'HoT' | 'guidance' |  'guidance2'
 *
 */
    mode=params.run_mode


/*
 * Select aligner method to generate MSA replicates:
 *
 * 'MAFFT' | 'CLUSTALW' | 'PRANK'
 *
 *  eg:  ${params.aligner} = 'MAFFT'
 */




/*
 *
 **************************/


/**************************
 *
 *   C R E A T E   S H U F F L E   S E Q   F I L E S
 *
 *   Shuffle the input order of the sequences
 */

process get_shuffle_replicates{

    publishDir "${params.output}/${datasetID}/shuffle_replicates", mode: 'copy'

    input:
        set val(datasetID), file(seq_file) from datasetsA

    output:
        set val(datasetID), file ("*.fa") into shuffle_replicatesA, shuffle_replicatesB mode flatten

    shell:
    '''
      seq_shuffle.pl !{seq_file} !{datasetID} !{seed} !{shuffle_num}
    '''
}

/*
 *
 **************************/


/**************************
 *
 *   C R E A T E   S H U F F L E   D E F A U L T  A L I G N M E N T S
 *
 *   Create alignments from shuffle replicates
 */

process get_shuffle_alignments{

    publishDir "${params.output}/${datasetID}/shuffle_replicate_default_alignments/", mode: 'copy'

    input:
        set val(datasetID), file(shuffled_seq_file) from shuffle_replicatesA

    output:
        set val(datasetID), file ("*.aln") into shuffle_default_alignmentsA, shuffle_default_alignmentsB, shuffle_default_alignmentsC

     shell: 
         template "${params.aligner}_shuffled_alignment"

}

/*
 *
 **************************/




/**************************
 *
 *   C R E A T E   G U I D A N C E / 2  |  H O T   A L T E R N A T I V E   A L I G N M E N T S
 *
 *   Generate the default (non-shootstrap) and shuffled alternative alignments using guidance2
 *   Outputs a directory containing the alternative alignments and the default alignment
 */

process default_alternative_alignments {
    tag "generate alternative alignments: $datasetID"

    publishDir "${params.output}/${datasetID}/default_${mode}_alignments/", mode: 'copy', overwrite: 'true'
  
    input:
    set val(datasetID), file(datasetFile) from datasetsB

    output:
    set val(datasetID), val(mode), val("default"), file ("scores") into defaultAlignmentsScores
    set val(datasetID), val(mode), val("default"), file ("alternativeMSA") into defaultAlignmentsDirectories  
    
    script:
    //
    // Alternative Alignments: Generating default alternative alignments
    //
    
    template "${mode}_default_alignments"
}

process shuffled_alternative_alignments {
    tag "generate alternative alignments: $datasetID"

    publishDir "${params.output}/${datasetID}/shuffled_${mode}_alignments/${shuffled_seq_file.baseName}/", overwrite: 'true'

    input:
    set val(datasetID), file(shuffled_seq_file) from shuffle_replicatesB

    output:
    set val(datasetID), val(mode), val("shuffled_seq_file.baseName"), file ("alternativeMSA") into shuffledAlignmentsDirectories
    set val(datasetID), val(mode), val("shuffled_seq_file.baseName"), file ("scores") into shuffledAlignmentsScores

    script:
    //
    // Alternative: Generating shuffled alternative alignments
    //

    template "${mode}_shuffled_alignments"
}


/*
 *
 **************************/

/*
 * set val(datasetID), val (mode), file ("alternativeMSA") into defaultAlignmentsDirectories
 */

/* defaultAlignmentsDirectories
 * .view()
 *
 *  .flatmap { id, mode, dir -> dir.listFiles().collect { [ id, mode, it ]} }
 */


/*
 *  set val(datasetID), file ("*.aln") into shuffle_default_alignments
 *
 *
*shuffle_default_alignmentsB
*  .groupTuple()
*  .set {shuffle_default_alignmentsB_grouped} 
*
*
*shuffle_default_alignmentsB_grouped
*  .cross(shuffle_default_alignmentsA)
*  .flatMap{ alpha, omega ->  [ alpha[1], omega[1]].combinations().collect { [alpha[0], it[1], it[0]] }  }
*  .filter { item -> item[1] != item[2] }
*  .set { shuffle_default_alignments_crossed }
*
*refAlns
* .cross(shuffle_default_alignmentsC)
* .map { it -> [ it[0][0], it[1][1], it[0][1] ] }
* .set { shuffle_default_alignments_with_ref }
*
*/

/**************************
 *
 *   C A L C U L A T E   S I M I L A R I T Y   O F   S H U F F L E D   M S A S 
 *
 *  
 *
 *
 * process similarity_of_shuffled_alternative_alignments{
 *
 *   publishDir "${params.output}/${datasetID}/similarity/", mode: 'copy'
*
*    input:
*        set val(datasetID), file (aln1), file(aln2) from shuffle_default_alignments_crossed
*
*    output:
*        set val(datasetID), file ("*.score") into shuffle_alignments_sim_scores
*
*     script:
*     """
*     t_coffee -other_pg aln_compare -al1 ${aln1} -al2 ${aln2} -compare_mode sp > ${aln1.baseName}_${aln2.baseName}.sp.score
*     t_coffee -other_pg aln_compare -al1 ${aln1} -al2 ${aln2} -compare_mode column > ${aln1.baseName}_${aln2.baseName}.column.score
*
*     """
*
*}
*/


/*
 *
 **************************/


/**************************
 *
 *   C A L C U L A T E   A C C U R A C Y   O F   S H U F F L E D   M S A S
 *
 *
 *
 *
*process accuracy_of_shuffled_alternative_alignments {
*
*    publishDir "${params.output}/${datasetID}/accuracy/", mode: 'copy'
*
*    input:
*    set val(datasetID), file (aln), file(ref_aln) from shuffle_default_alignments_with_ref
*
*    output:
*    set val(datasetID), file ("*.score") into shuffle_alignments_acc_scores
*
*    script:
*    """
*    t_coffee -other_pg aln_compare -al1 ${aln} -al2 ${ref_aln} -compare_mode sp > ${aln.baseName}_ref.sp.score
*    t_coffee -other_pg aln_compare -al1 ${aln} -al2 ${ref_aln} -compare_mode column > ${aln.baseName}_ref.column.score
*
*    """
*
*}
*/

/*
 *
 **************************/

