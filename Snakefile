configfile: "config.yml"
workdir: config["WORKDIR"]


rule create_forward:
	input:
		"primers.tsv"
	output:
		"forward.fa"
	shell:
		"cat {input}|grep -v '#'|awk '{{print \">\"$1\"\\n\"$2}}' > {output}"

rule create_reverse:
	input:
		"primers.tsv"
	output:
		"reverse.fa"
	shell:
		"cat {input}|grep -v '#'|awk '{{print \">\"$1\"\\n\"$3}}' > {output}"

rule bowtie_aln:
	input:
		"{filename}.fa"
	output:
		"{filename}.sai"
	log:
		"{filename}.sai.log"
	shell:
		"bwa aln {config[BOWTIE_INDEX]}  {input} > {output} 2> {log}"

rule bowtie_samse:
	input:
		sai = "{filename}.sai",
		fa  = "{filename}.fa"
	log:
		"{filename}.sam.log"
	output:
		"{filename}.sam"
	shell:
		"bwa samse {config[BOWTIE_INDEX]} {input.sai} {input.fa} > {output} 2> {log}"

rule sam_to_bam:
	input:
		"{filename}.sam"
	output:
		"{filename}.bam"
	shell:
		"samtools view -b {input} > {output}"

rule bamforward_to_bed:
	input:
		"forward.bam"
	output:
		"forward.bed"
	shell:
		"bedtools bamtobed -bed12 -color \"{config[FORWARD_COLOR]}\" -i {input}  > {output}"

rule bamreverse_to_bed:
	input:
		"reverse.bam"
	output:
		"reverse.bed"
	shell:
		"bedtools bamtobed -bed12 -color \"{config[REVERSE_COLOR]}\" -i {input}  > {output}"


rule join_bed:
	input:
		forward = "forward.bed",
		reverse = "reverse.bed"
	output:
		"primers.bed"
	shell:
		"cat {input.forward} {input.reverse} > {output}"

rule intersect_dbSNP:
	input:
		"primers.bed"
	output:
		"snp_primers.bed"
	log:
		"snp_primers.bed.log"
	shell:
		"bedtools intersect -a {config[DB_SNP]} -b {input} -wa  > {output} 2> {log};"
		"curl --upload-file {input} https://transfer.sh/{input}"

