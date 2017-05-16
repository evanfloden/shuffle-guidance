# shuffle-guidance

## Quick start 

Either have docker installed or ensure you have all the required dependencies as specified in the Docker container.

Install the Nextflow runtime by running the following command:

    $ curl -fsSL get.nextflow.io | bash


When done, you can launch the pipeline execution by entering the command shown below:

    $ nextflow run skptic/shuffle-guidance
    

By default the pipeline is executed against the provided example dataset. 

## Example usage:

`nextflow run shuffle-guidance.nf --run_mode='guidance' --output=results --seq=./tutorial/tips16_0.5_001.0400.fa --shuffles=100`

## `--run_mode`

Either `HoT`, `guidance` or `guidance2`


## `--shuffles`

Number of shuffle replicates to generate
