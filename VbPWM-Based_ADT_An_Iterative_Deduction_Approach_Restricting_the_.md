<!-- IEEE TRANSACTIONS ON CIRCUITS AND SYSTEMS-I: REGULAR PAPERS, VOL. 72, NO. 8, AUGUST 2025 4195 -->

# VbPWM-Based ADT: An Iterative Deduction

# Approach Restricting the Traversal of

# MPWM at the Cost of In-Band SNR

Yujie Xian®,Kai Gao,Shang Ma,Kaijiang Li,and Jian Wang

Abstract-Based **on the concept of mapping-based pulse** width **modulation (MPWM), the look-up-table-based all-digital** transmitter **(LUT-based ADT) achieves high signal-to-noise ratio** (SNR) and **low error vector magnitude (EVM) by leveraging** a stored **mapping from the baseband complex sample to the** output binary **sequence, while itshigh RAM consumption and** LUT generation **complexity hinder its further usage. Toward** a RAM-free and **traversal-free ADT based on MPWM, in this** paper,we model **the MPWM process as an optimization problem** and correspondingly **construct a Viterbi-based PWM (VbPWM)** modulator scheme, **featuring real-time deduction of the 1-bit** sequence from **the input complex sample and a traversal-free** computation **process. Fixed points simulations suggest that the** deduced local **optimum demonstrates a 10 dB SNR loss compared** with the global **optimum of MPWM, while this loss can be** further eased **by 2-3 dB after introducing a simplified simulated** annealing **algorithm. Additionally, a fully serial and pipelined** implementation **structure is proposed to unfold the iterations** into cascading **iteration units,thereby achieving run-time recon-**figurable **carrier frequencies and minimizing block read-only** memory (BRAM) **usage. EVMs of the proposed ADT with carrier** frequencies **ranging from 0.6 GHz and 7.6 GHz under different** symbol rates **are measured with ZCU102, presenting an increas-**ing trend **associated with carrier frequency and symbol rates.** Consequently,compared **with the original MPWM, a 1% loss of** EVM is revealed **under 5 MBaud of symbol rate for all measured** frequencies. **The maximum EVM under 5 MBaud is measured** as 3.5%, **while the maximum for 25 MBaud and 50 MBaud is** 5% and **5.8%,respectively. The RAM usage is then minimized** to a single **36K tile and the traversal of MPWM is removed.**

Index Terms-All digital **transmitter (ADT), mapping-based** **pulse width modulation (MPWM), Viterbi algorithm, field-programmable gate array (FPGA), radio frequency (RF).**

# I. INTRODUCTION

**T**including radio frequency (RF) digital-to-analog convert-OWRAD a highly integrated transmitter,recent products ers (DACs) [1] or integrated RF front-end enables a compact transmitter structure, among which the scheme of the all-digital transmitter (ADT) has driven focus due to its agility, cost-efficiency and reconfigurability. Previously constructed within digital signal processors (DSP) in the early days [2],the ADT is currently carried out by field-programmable-gate-array (FPGA) integrated with high-speed serial transceiver,which

Received 20 August 2024; revised 30 October 2024; accepted 13 November 2024. Date of publication 25 November 2024; date of current version 30 July 2025. This article was recommended by Associate Editor L. Gan. (Corresponding author: Shang Ma.)

The authors are with the National Key Laboratory of Wireless Communications, University of Electronic Science and Technology of China, Chengdu 611731, China (e-mail: mashang@uestc.edu.cn).

Digital Object Identifier 10.1109/TCSI.2024.3502358

achieves higher carrier frequencies and signal bandwidths, therefore making the ADT more applicable for actual applica-tions. Moreover, its simplicity and single-chip solution enable possibilities of the fully software-defined radio (SDR) [3]. The basic concept of ADT leverages the 1-bit modulator,i.e., pulse width modulation (PWM) and ΔΣ modulation (DSM), to modulate the complex sample into a 1-bit sequence over a high sample rate. In the previous ADT scheme, as addressed in [4], trade-offs between modulation performance, frequency agility,and resource consumption are raised. To ensure a higher over-sample rate toward less in-band quantization noise, schemes that assert modulation unit before digital up-converted (DUC) [5],[6],[7] have simplified the modulator's design, though at the cost of frequency agility. In contrast, performing DUC before modulation [5], [8],[9] ensures frequency agility at the cost of high sample rate. The other trade-off lies in balancing resource consumption with perfor-mance, specifically signal-to-noise ratio (SNR). While PWM offers great resource efficiency [10], [11],[12],it introduces significant harmonic distortion, providing an active research area focusing on its noise shaping [13]. Conversely, DSM, despite requiring greater resources and stricter timing due to its feedback loop with filters [8], achieves superior in-band SNR. Thereby, previous works [14], [15],[16] incline to the DSM scheme in favor of its higher SNR and less harmonic disrup-tion, as in [17] a 1GHz of clean bandwidth has been achieved with DSM. Moreover, a trend is to leverage multiple-level pulses (like PAM-4 in [18] or multiple-level PWM in [19], [20],and [21]) based on the existing modulators for the ADT scheme, enhancing its SNR or eliminating certain harmonics.

Despite the conventional approaches and their combination in [22] and [23], a novel modulation scheme has been pro-posed in [24] and [25] other than PWM or DSM, namely mapping-based PWM (MPWM), that fundamentally solves the aforementioned trade-offs. Instead of interpreting the modula-tion process through transpose functions [8], [26],the MPWM establishes a relationship between the complex input of the modulator and the 1-bit equivalent output by defining the modulated signal in the 1-bit equivalent at the target carrier fre-quency, where the modulator's mission is to sort out the 1-bit sequence possessing the least distance with the complex input. This optimization problem, described in [25], is currently solved by transversing all possible inputs to find their related sequence ahead, afterward the sorted sequences are stored in the on-board LUT. Furthermore, the target function in the optimization problem is updated in [21] towards a higher

1549-8328 © 2024 IEEE.Personal use is permitted, but republication/redistribution requires IEEE permission.

See https://www.ieee.org/publications/rights/index.html for more information.

<!-- Authorized licensed use limited to: Nanjing University of Information Science and Technology. Downloaded on September 03,2025 at 07:16:48 UTC from IEEE Xplore. Restrictions apply. -->

<!-- 4196 IEEE TRANSACTIONS ON CIRCUITS AND SYSTEMS-I: REGULAR PAPERS, VOL. 72, NO. 8, AUGUST 2025 -->

clean bandwidth along with the extension to the 3-level pulse, and in [27], the usage of the LUT-based ADT is extended to dual-band applications, both demonstrating the compliance and flexibility of the LUT-based ADT in different situations.

While achieving a high in-band SNR of 40dB,complexity when generating this LUT cannot be easily neglected, as for each possible input, another traversal is conducted on all sequences to find the target one. Additionally, the RAM consumption of the LUT-based ADT also poses a challenge for small-scale FPGAs. It is clear that RAM consumption will be enlarged if the output sequence's width (which is N in the latter discussion) or the input sample's width is extended, along with the computation complexity when generating the required LUT. To ease this increase,works have been proposed to reduce the RAM usage, for instance in [20] and [28] the number of RAM has been reduced by half or more compared with the original [25].However, this encouraging reduction comes at a cost, where in [28] the LUT is constructed within the DSM scheme instead of the original MPWM, and in [20] the reduction is based on implementing a 5-level PWM whose hardware structure is left unclear if implemented in FPGAs. Moreover, the LUT needs to be re-computed and updated each time after reconfiguring the carrier frequency with certain values, making it hard for real-time reconfiguration. These mentioned factors have motivated us to consider whether this optimization problem could be solved in real-time without any former traversal.

By formulating the MPWM process as an optimization problem, in this paper, a Viterbi-based MPWM (VbPWM) scheme is proposed inspired by the coding principle of MPWM. Compared with the previous LUT-based structure, the proposed structure presents the following advantages at the cost of SNR and additional resource consumptions:

·the proposed scheme minimizes the RAM consumption to a single 36K tile while sticking to the original MPWM principle;

·the proposed scheme enables real-time reconfigurability of carrier frequency without any additional computation ahead;

The remainder of this paper is organized as follows: the concept of the ADT and the MPWM scheme are dis-cussed in Section II; the VbPWM scheme is demonstrated in Section III along with an iteration instant; in Section III-B numerical simulations are conducted to depict the perfor-mance loss compared with the original MPWM work due to enlarged inter-frequency (IF) quantization noise; a fully serial pipeline structure of the VbPWM-based ADT is proposed in Section IV, where the implementation structure of each unit is introduced in Section IV-A, along with the hardware verification in Section IV-B and Section IV-C. The conclusion is in Section V.

# II. BACKGROUND

Before introducing the VbPWM scheme, firstly we will review the typical ADT structure and the LUT-based ADT structure to form the theoretical background of this work.

<!-- I/Q ≤ RF Sample ... Sample Sample b RF Front End PWM Gigabit FIR DUC Tran fBB fIF fIF DSM -sceiver Polyphase Polyphase Multiple fIF fRF Filter PA Interpolation Up-conversion Modulators -->
![](https://web-api.textin.com/ocr_image/external/a92124e43bcfd851.jpg)

Fig. 1. Simplified block diagram of a fully parallel PWM/DSM-based ADT structure. N is the number of parallel lanes and also the input width provided by the gigabit transceiver IP.

## A. Typical PWM/DSM-Based ADT Structure

One typical parallel DSM or PWM-based ADT structure in [4] with a fully parallel implementation structure is sum-marized by the block diagram in Fig. 1, whose input is the baseband complex sample at the sample rate fBB. Its output is the 1-bit sequence sampled at the RF rate fRF serial-ized using the gigabit transceiver from the modulator's N-bit product. Four major modules are involved in this modulation-after-conversion structure whose functions are individually described as follows:

1) Polyphase interpolation: interpolate the complex sample from the baseband sample rate fBB to the RF sample rate fRF. This process is usually conducted through a polyphase Finite Impulse Response (FIR) filter with N-parallel outputs, whose sample rate for each lane is denoted by the inter-frequency (IF) sample rate ifIF wherefIF=fRF/N

2) Polyphase up-conversion: up-convert the interpolated sample from the baseband to the target carrier frequency with a set of N-phase carriers generated by the polyphase Direct digital frequency synthesizer (DDS).

3) Multiple modulators: modulate the up-converted sample into a 1-bit sequence. For fRF less than the maximum clock rate of FPGA, a single modulator is enough to transfer the sample. However, if fRF exceeds the limit,polyphase decomposition is employed, distributing samples across multiple parallel lanes operating at the speed of fIF. The combined output from all N lanes constitutes an N-bit sequence sampled at fIF.

4) Gigabit transceiver: serialize the N-bit binary sequence from the parallel modulators into a 1-bit RF equivalent at the sample rate of fRF.

Theoretical proof for the existence of the baseband signal in the RF 1-bit sequence is given by the transpose function of DSM:

$$Y(z)=H_{x}(z)X(z)+H_{e}(Z)E(z),\tag{1}$$

whereY(z),X(z), and E(z) are the z-domain expression of the output, input, and quantization noise of the DSM. Hx(z)andH(z)are the different responses in the loop for X(z) and E(z),which forms the DSM's band-limit-shaped noise without causing signicant distortion to X(z). While the optimization of **DSM** is carried out under the guidance of this z-domain transpose function to design different Hx(z) andH(z),the **MPWM** scheme in [24] and [25] possess a different coding principle from time domain. We will discuss this coding principle and its current implementation drawbacks in the following Section II-B.

<!-- Authorized licensed use limited to: Nanjing University of Information Science and Technology. Downloaded on September 03,2025 at 07:16:48 UTC from IEEE Xplore. Restrictions apply. -->

<!-- XIAN et al.: VbPWM-BASED ADT: ANITERATIVE DEDUCTION APPROACH RESTRICTING THE TRAVERSAL OF MPWM 4197 -->

<!-- I/Q IF *IF Sample Sample Sample 6 bit RF Front End Gigabit FIR DUC LUT Tran -sceiver fBB Polyphase fIF *Phase fIF Multiple fIF fRF Filter PA Interpolation Compensation LUT -->
![](https://web-api.textin.com/ocr_image/external/74b3b7d85da9b839.jpg)

Fig.2. Simplified block diagram of a LUT-based ADT structure. The input width of the gigabit transceiver module is assumed as 64-bit,and 4 parallel lanes are placed with a 16-bit LUT asserted in each lane. The sample rate fIF for each parallel lane is 250 Msps if the RF sample ratefRFor the RFpulse is assumed as 16 Gsps.(*Though the DUC module is described as frequency up-conversion in [25], we consider it is more accurate to describe the DUC module as a phase compensation (PC) unit to compensate for the initial phase of the virtual carrier-j2πfcTRF in use during the generation of $\tilde {p}[n]$  in (6). As the generation of $\tilde {p}[n]$  is accomplished with a 0-initial-phhase carrier in (6) but the carrier's phase may not coincidentally return to 0 at every beginning of the RF sequence, compensation is necessary to ensure the carrier's phase continuity between two sequential $\tilde {p}[n]$ .)

## B. LUT-Based ADT Structure

In [24], the author provides the relation between the 1-bit sequence over a certain observation duration and the mod-ulated signal of the 1-bit sequence on the target carrier in a continuous-time manner, and in [25] a discrete-time expression is proposed for digital implementation as

$$q_{i}=\frac {1}{N}\sum _{n=0}^{N-1}p_{i}^{*}[n]e^{-j2\pi f_{c}T_{RF}n}\quad =\frac {1}{N}\sum _{n=0}^{N-1}\left(2p_{i}[n]-1\right)e^{-j2\pi f_{c}T_{RF}n}\tag{2}$$

where qi is defined as the modulated baseband sample at the carrierfc. N is the observation length (or the sequence length),fc is the claimed carrier frequency, and TRFis the sample interval of the RF 1-bit sequence. pi[n] is the 1-bit sequence in this duration, which can be denoted as an N-bit binary sequence. According to the principle in [25], all bits 0 in pi[n] should be replaced with -1 when calculating qii, which is expressed aspi*[n]=2pi[n]-1in(2),wherepi*[]is the sequence after replacement and composed of bit 1 and -1.As (2)only reveals the exact modulated sample over a partic-ular sequence without proposing a valid modulation function from the input sample to the output sequence, a compromised solution is presented for MPWM to construct a LUT ahead with fixed parameters, where the crucial 1traversals used to generate the LUT are presented below in Section II-B2.

1) Structure of LUT-Based ADT: The aforementioned LUT-based ADT is utilized with a different architecture in contrast to the conventional one, and the most obvious difference conceived from Fig. 2 is the reduced parallel lanes. Under the given input width of the GTH port as 64 bits and RF sample rate of 16 Gbps, the amount of parallel lanes is reduced from 64 to 4 for LUT-based ADT, where this number is determined by the LUT's 16-bit output and the transceiver's 64-bit input.

Signal processing for the LUT-based ADT is performed as follows: the complex baseband input is first interpolated from the baseband sample rate fBB to the IF sample rate fI=fR/16=1Gsps, with 4 parallel lanes individually sampled at 250 Msps; then a polyphase phase compensation is performed for each lane; afterward, the corrected sample is provided for the LUT, fetching 16-bit sequences at the rate of 250 Msps; gathered from the four lanes, the four 16-bit sequence $\tilde {p}[n]$  are concatenated to a 64-bit sequence at a rate of 250 Msps and is serialized trough GTH, resulting in the RF pulse sampled at 16 Gbps.

2) Modulation Process of MPWM-Type LUT-Based ADT: Both the MPWM in [24] and the LUT-based ADT in [25] describe the modulation process as a mapping procedure. This procedure involves associating the input signal with the nearest quantized value qi and subsequently generating the corresponding output sequence pi[n]. In essence, the mapping process identifies pi[n] that produces the modulated signal at the carrier frequency most closely resembling the input,and then the identified sequence is labeled as the corresponding sequence for the given complex input.

Specifically, if given a sequence length of N, a mapping is constructed to connect set Q and P by constructing set P first and calculating Q according to (2) as

$$\mathcal {Q}=\left\{q_{i}|i\in \left[0,2^{N-1}\right]\right\}\tag{3}$$

and   和

$$\mathcal {P}=\left\{p_{i}[n]|p_{i}[n]=\text {Oor}1,i\in \left[0,2^{N}-1\right],n\in [0,N-1]\right\}$$

(4)

through which the mappingP→Qis constructed.Afterward, a traversal on all possible baseband complex sample y under a limited resolution is performed to construct the set y, and in [25] 16 bits are utilized to denote each y in the uniformed polar coordinate. The mappingY→Qis achieved by iterating through each y in y and finding the corresponding qi in Q that minimizes the Euclidean distance|y-qi|.Subsequently,the mappingsP→QandY→Qare conjoined to consruct the mappingY→Pby traversals. Through this process,for each entry in y, a corresponding N-bit sequence $\tilde {p}[n]$  is selected from P according to

$$\tilde {i}(ρ,\theta )=\underset {i}{\text {argmin}}\left|\frac {q_{i}}{\max (|\mathcal {Q}|)}-r\frac {ρe^{j\theta }}{\max (ρ)}\right|\tag{5}$$

where ρ and θ represent the amplitude and phase of y in polar coordinate. r is a scaling factor issued in [25] for minimizing quantization noise under different carrier frequencies and symbol rates, and the authors address that different set Q requires differentr to achieve its minimum quantization noise. The $\tilde {p}[n]$  is then selected from P with the index $\tilde {i}(ρ,$ θ)and stored in the LUT corresponding to the current y.

As the mapping ofY→Pis achieved by finding the nearest qi from set Q and storing the corresponding pi[n],it is appropriate to characterize the modulation process as an optimization problem:

$$\tilde {p}[n]=\underset {p_{i}[n]}{\text {argmin}}\left|y-\frac {1}{N}\sum _{n=0}^{N-1}p_{i}^{*}[n]e^{-j2\pi f_{c}T_{RF}n}\right|\quad =\underset {p_{i}[n]}{\text {argmin}}\left|y-\frac {1}{N}\sum _{n=0}^{N-1}\left(2p_{i}[n]-1\right)e^{-j2\pi f_{c}T_{RF}n}\right|$$

$$\text {s.t.}p_{i}[n]\in \mathcal {P}\tag{6}$$

<!-- Authorized licensed use limited to: Nanjing University of Information Science and Technology. Downloaded on September 03,2025 at 07:16:48 UTC from IEEE Xplore. Restrictions apply. -->

<!-- 4198 IEEE TRANSACTIONS ON CIRCUITS AND SYSTEMS-I: REGULAR PAPERS, VOL. 72, NO.8, AUGUST 2025 -->

From this perspective, the generation of LUT can be viewed as a traversal over all possible input y, and for each y additional traversals are performed to solve (6). The obtained $\tilde {p}[n]$  turns out to be a global optimum as all possible solutions are evalu-ated to find the solution. However, this comprehensive search significantly involves computational complexity of nearly2N for only calculating Q, not to mention the mapping Y→Q, which is also utilized through traversal.

What's more, while in [25] authors proved that larger sequence length leads to less RF quantization noise, con-structing set P and its related mapping becomes challenging for sequence lengths exceeding 32 bits. This limitation arises from the exponential increase in the complexity of the com-prehensive search and the corresponding growth in RAM usage. Consequently, the authors restricted their result to a maximum sequence length of 32 bits in simulations. However, by weighing the performance enhancement offered by an extended length, we identify opportunities for optimization to enable adjustable output width,decreased complexity for extended sequence lengths, and lower RAM requirements. Therefore, in the following Section III, a modulation scheme utilizing the principle of MPWM is proposed based on the concept of the Viterbi algorithm, implementing an **MPWM** modulator without requiring pre-generation of the mapping or the LUT. Instead, it deduces a suboptimal sequence directly from the baseband complex sample.

# III. SCHEME OF THE PROPOSED VBPWM AND ITS

# SIMULATION EVALUATION

Instead of solving (6) using pre-generated LUT, the VbPWM takes a traversal-free way of solving the optimization problem in (6), i.e., leveraging the concept of the Viterbi algorithm to deduce a local optimum from the baseband complex sample in real-time. As the output of the conventional encoder is generated by the linear feedback shift register (LFSR) through its operations on the input, the Viterbi decoder derives the most likely input of the encoder by simulating the update of LFSR's state inside the encoder, where the update process producing the closest output to the decoder's input (or encoder's output) is considered as the most possible state update process in the encoder. Afterward, the decoder's output is generated from this deduced chain. For the proposed VbPWM scheme, a similar process is employed to deduce $\tilde {p}[n]$  bit-by-bit from n=0ton=N-1,which adopts the concept of deducing the most likely update process. The related sequence after the state update process, yielding the minimum Euclidean distance to the desired output, is then selected as the deduced output of the VbPWM.

Based on the conception of the VbPWM, the design of the VbPWM ADT originates from the MPWM-type LUT-based ADT and is shown in FFig.3,where the main difference of VbPWM ADT is the replacement of the LUT with the VbPWM module. More specifically, while the MPWM-type LUT-based ADT achieves the globally optimized solution $\tilde {p}[n]$  through traversal, the VbPWM scheme deduces a local optimum $\tilde {p}^{\prime }[n]$ from its input within a restricted number of iterations, therefore achieving an arbitrary output sequence length N which reduces the 4 parallel lanes in [25]. The agility

<!-- I/Q I/Q IF S bit Sample Sample Sample Gigabit RF Front End Tran FIR DUC sceiver fBB fIF fIF fIF fRF Polyphase Phase Filter PA Interpolation Compensation VbPWM -->
![](https://web-api.textin.com/ocr_image/external/48075c1fd9bbb833.jpg)

Fig.3. Systematic structure of VbPWM ADT.

TABLE I

SYMBOL DEFINITION

<table border="1" ><tr>
<td>Symbol</td>
<td>Definition</td>
</tr><tr>
<td>pa(i)[n]la(i)</td>
<td>the survival path of node a in iteration i</td>
</tr><tr>
<td>pa(x)(i)[n]</td>
<td>the survival path length of node a in iteration <br>i;</td>
</tr><tr>
<td></td>
<td>the possible paths generated by node a in iteration i</td>
</tr><tr>
<td></td>
<td>This path ends with the LSB x, which is bit 0 or bit 1;</td>
</tr><tr>
<td>la(x)(i)</td>
<td>the path length for possible pathpa(x)(i)</td>
</tr></table>

in sequence length also decreases the interpolation factor when raising the sample rate from fBB to fIF and even enables bypassing the interpolation module iffBB=fIF,which offers significant advantages of reducing computational complexity.

In the following section, the VbPWM will be discussed based on the iteration instant and the trellis graph provided in Section III-A, through which we will demonstrate how the VbPWM deduce a local solution of (6) according to the baseband complex sample. Crucial symbols used in the current section and further implementation are listed in Table I.

## A. An Iteration Intance of the VbPWM

For typical Viterbi decoders, the concept of nodes is defined to represent the possible state of the encoder's LFSR at each time step, and iterations are introduced to model the step-by-step progression of the LFSR states. At each time step,every node considers two possible inputs (0 or 1) to the encoder's LFSR, which would lead to two potential next states.For each of these potential transitions, the node calculates a new path by extending its current path with the corresponding output bit. These new paths are then associated with theappropriate nodes in the next time step,representing the potential next states of the LFSR. Consequently,each node in the new time step receives two incoming paths from different predecessor states. The decoder compares these incoming paths against the actual received sequence, selecting the path that best matches the received data as the 'survival path' for that node. This survival path represents the most likely sequence of state transitions and inputs that led to this particular state, given the received data up to this point. This process repeats for each time step, allowing the decoder to incrementally build and refine its estimate of the most likely transmitted sequence.

Inspired by the decoding process of Viterbi decoder, we introduce similar concepts of node and iteration into the MPWM scheme to perform the proposed VbPWM for deducing the most possible sequence containing the closest qi with y. A trellis graph is presented in Fig. 4 with the memory lengthlm=2For each iteration, the possible input bit is directly added to the end of survival paths, and the updated

<!-- Authorized licensed use limited to: Nanjing University of Information Science and Technology. Downloaded on September 03,2025 at 07:16:48 UTC from IEEE Xplore. Restrictions apply. -->

<!-- XIAN et al.: VbPWM-BASED ADT: AN ITERATIVE DEDUCTION APPROACH RESTRICTING THE TRAVERSAL OF MPWM 4199 -->

<!-- Iteration Iteration Iteration Iteration Iteration 0 1 2 3 N 00 0 00 00 00 000 00 00 001 001 l0(0)p0(0) l0(l)p0(l) 01 l0(2)p0(2) l0(3)p0(3) l0(N)p0(N) min(l0(N-1),l1(N-1),l2(N-1),l3(N-1)) 01 1 01 01 100 10 01 01 l1(0)p1(0) l1(l)p1(l) 10 l1(2)p1(2) l1(3)p1(3) l1(N)p1(N) \widetildep[n] 010 10 10 10 10 10 l2(0)p2(0) l2(l)p2(l) 11 l2(2)p2(2) 110 011 l2(3)p2(3) l (N) (2) 2 P2 11 11 11 111 11 11 l3(0)p3(0) l3(1)p3 l3(2)p3(2) l3(3)p3(3) l3(N) p3(N) -->
![](https://web-api.textin.com/ocr_image/external/46ce21395da42363.jpg)

Fig.4. Trellis graph example of the VbPWM. The memory lengthlm of the Viterbi decoder is assumed as 2 and therefore four nodes {00},{01},{10},{11} are included during iterations. Survived pathpi(j)is related to the node i for the jth iteration. The arrows in the figure represent the transmitted survival path of each node between iterations and the transparent (or gray) arrow in the figure represents the discarded path which possesses a greater length. Though the path presented turns out a binary, the 0 for each pathpi(jneeds to be replaced with -1 when calculating path length according to the principle (6).

state is told from the least 2 significant bits of the possible path. An iteration instant is given as follows with a total of N+1iterations conducted along with2mnodes:

1)Firstly all 2lm nodes are initialized with the initial survival pathpj(0)[n]and the initial path lengthlj(0)for j=0,1,⋯,2lm-1. The lower j in pj(0)[n]andlj(0) denotes the node's index, i.e., node 0 corresponding to j=0.. The upper bracket (0) represents the iteration time. As the initial survival path is not crucial for latter iterations,pj(0)[n]is initialized with uninterested value X so that ∀n∈[0,N-1],pj(0)[n]=X. The initial path lengthlj(0)is simply the input complex sample y.In addition,We assume that iteration starts from node {0,0} (or node 0) for ease of description, which is presented in Fig. 4.

2) For iteration 0, two input bits 0 and 1 are considered, resulting in two branches from initial node 0 whose out-put bit is 0 and 1, respectively. Therefore, the generated possible pathsp()()[n]andp(1)()for the two branches are

$$\left\{p_{0(0)}^{(0)}[n]\right\}=\left\{p_{0}^{(0)}[N-2:0],0\right\}=\{X,X,\cdots ,X,0\}$$

(7)

and   和

$$\left\{p_{0(1)}^{(0)}[n]\right\}=\left\{p_{0}^{(0)}[N-2:0],1\right\}=\{X,X,\cdots ,X,1\}$$

(8)

p0(0)[N-2:0]stands for the least N-2 bits of the survival path p0(0) for node 0. The bracket below represents the branch's output bit and the bracket above represents the current iteration time. As terminals of these possible paths are determined by their leastlm bits, the updated states for p0(0)(0)[n] andp0(1)(0)[n]can be expressed as node (X,X,...,0)and(X,)X,...,1) or node (0,0,...,0)(node 0's binary expression) and (0,0,...,1) (node 1's binary expression) if X is treated as 0. In Fig. 4, two paths {0} and {1} marked in bronze are generated from node 0, and are transmitted to node (0,0) (node O's binary expression when .lm=2)and node (0,1) (node 1's binary expression when .lm=2) respectively.

3) For iteration 1, node0 and node 1 receives possible paths from previous iteration 0, computing the possible paths' lengthl0(0)(0)[]andl0(1)(0)[]as:

$$l_{0}^{(0)}=l_{0(0)}^{(0)}=y-\frac {1}{N}p_{0(0)}^{*(0)}[0]e^{-j2\pi f_{c}/f_{s}*0}\stackrel {(a)}{=}y+\frac {1}{N}$$

(9)

and

$$l_{0}^{(1)}=l_{0(1)}^{(0)}=y-\frac {1}{N}p_{0(1)}^{*(0)}[0]e^{-j2\pi f_{c}/f_{s}*0}\stackrel {(a)}{=}y-\frac {1}{N}$$

(10)

where the expressionp0(0)*(0)[n]=2p0(0)(0)[n]-1 replaces bit 0 in p0(0)(0)with -1 and the same operation applies to p(1)*()[[n]. To take another perspective, the path lengths in(9) and (10) can be viewed as the corresponding qi for the pathp0(0(0[]andp0(1(0[]all Xs in the possible path are treated as 0 during calculation according to (2). In addition, the survival path is updated by each node appending the possible path with the least |qi| to its local path, in other words, the least distance with input y. Based on this description, the VbPWM process min-imizes the distance to y or |qi| of all survival paths at each iteration stage, in the end minimizing the objective function in (6). Thereby, node 0 and node 1 directly update their survival pathp()[]and p()[]with the shortest possible pathp0(0)(0)[n]and p0(1)(0)[n],,while the survival path lengthl0(1)andl1(1) are updated from the possible paths' length in (9) and (10).

Once the survival path and path length are updated,node 0 generates two possible pathsp0(0)(1)[n]andp0(1)(1)[n]as

$$\left\{p_{0(0)}^{(1)}[n]\right\}=\left\{p_{0}^{(1)}[N-2:0],0\right\}=\{X,\cdots ,X,0,0\}$$

(11)

<!-- Authorized licensed use limited to: Nanjing University of Information Science and Technology. Downloaded on September 03,2025 at 07:16:48 UTC from IEEE Xplore. Restrictions apply. -->

<!-- 4200 IEEE TRANSACTIONS ON CIRCUITS AND SYSTEMS-I: REGULAR PAPERS, VOL. 72, NO.8, AUGUST 2025 -->

**and**

$$\left\{p_{0(1)}^{(1)}[n]\right\}=\left\{p_{0}^{(1)}[N-2:0],1\right\}=\{X,\cdots ,X,0,1\}$$

(12)

while node 1 generates the paths

{p1(0)(1)[n]}={p1(1)[N-2:0],0}={X,⋯,X, 1. 1,0}

(13)

and

$$\left\{p_{1(1)}^{(1)}[n]\right\}=\left\{p_{1}^{(1)}[N-2:0],1\right\}=\{X,\cdots ,X,1,1\}$$

(14)

Afterward, all paths are transmitted to their terminals according to their leastlm bits. For the situation in Fig.4,after receiving path {0} from node 0 in iteration 0, node 0 in iteration 1 produces paths {0,0} and {0,1}while node 1 produces paths {1,0} and {1,1} from its survival path {1}. The terminals for the aforementioned four paths are respectively node (0,0) (node 0), node (0,1) (node 1), node (1,0) (node 3's binary expres-sion) and node (1,1) (node 4's binary expression) in iteration 3.

The same procedure is shared from iteration 1 to itera-tionlmand during each iteration the node directly stores its received path. After iterationlm,it is assumed that all nodes' survival paths have been updated with a valid state value (replacement for undefined value X), hence all nodes in the coming iterationlm+1will produce two possible paths according to the two possible inputs.

4) For iteration j located in the range from iteration l+1to iteration N-1,each node firstly stores its inputpa(x)(j-1)[n]andpb(x)(j-1)[n] from the j-1th iteration. Symbols a and b below represent the previous nodes producing the possible paths, and x in the lower bracket denotes the output bit, which is the LSB of the possible path. Afterward, the corresponding length for possible pathpa(x)(j-1)is calculated as

$$l_{a(x)}^{(j-1)}=y-\frac {1}{N}\sum _{n=0}^{j-1}p_{a(x)}^{*(j-1)}[n]e^{-j2\pi f_{c}T_{RF}n}\tag{15}$$

where the same process is applied to pathpb(x)(j)[n]for producing its lengthlb(x)(j-1). As mentioned in iteration 1, during each iteration we make sure that all nodes' sur-vival paths are updated from the possible path possessing less distance with y or less |qi|l, and for node i this process is described as

$$p_{i}^{(j)}[n]=\left\{\begin{array}{l}p_{a(x)}^{(j-1)}[n],\left|l_{a(x)}^{(j-1)}\right|<\left|l_{b(x)}^{(j-1)}\right|\\ p_{b(x)}^{(j-1)}[n],\left|l_{b(x)}^{(j-1)}\right|\leq \left|l_{a(x)}^{(j-1)}\right|\end{array}\right.\tag{16}$$

Afterward, two possible paths pi(0)(j)[n]and pi(1)(j) are presented based on the node i's survival path as

$$p_{i(0)}^{(j)}[n]=\left\{p_{i}^{(j)}[N-2:0],0\right\}\tag{17}$$

and

$$p_{i(1)}^{(j)}[n]=\left\{p_{i}^{(j)}[N-2:0],1\right\}\tag{18}$$

As for the situation inFig. 4, in iteration 3 all nodes receive the possible paths produced in iteration 2. For instance:

·Node 0 receives two paths: {0,0,0} and {1,0,0}

·Node 1 receives two paths: {0,0,1} and {1,0,1}

In the context of equation (15), for node 0:

·Node a refers to node 0 from the previous iteration

·Node b refers to node 2 from the previous iteration

· x in the below bracket is bit 0

According to the mentioned process, path lengths of all possible paths are computed to acquire the least length path for updating each node's survival path, and the survival paths turn out to be {0, 0,0} for node 0, {1,0,1} for node 1 and so on.

5) For iteration N, the update of the survival path and path length is the same with the iteration fromlm toN-1. Afterward, no longer does the node produce its two possible paths, but the survival path of all nodes will be gathered and the path with the least path length among 2lmnodes is elected as the output binary sequence $\tilde {p}^{\prime }[n]$ :

$$\tilde {p}^{\prime }[n]=p_{\tilde {i}}^{\left(2^{N}\right)}[n]\tag{19}$$

where

$$\tilde {i}=\underset {i}{\text {argmin}}\left|l_{i}^{\left(2^{N}\right)}\right|\tag{20}$$

Therefore within N+1 times of iteration a deduced sequence $\tilde {p}^{\prime }[n]$  is produced from 2lm nodes.Though during iterations we let each node update its survival path from the paths closest to y, the output sequence could still be a local optimum referred in the optimization problem in (6) as the exact memory length involved in this problem is not clear. It would be straightforward to solve the global optimum $\tilde {p}[n]$ by settinglm=N, as this will turn the Viterbi algorithminto a simple traversal on set P, but the resource consumption of the VbPWM only allows for a memory lengthm≤3according to the implementation results in Table II. This inadequate mem-ory length eventuallyand unavoidably degrades the overall SNR and EVM due to the less optimal solution of $\tilde {p}^{\prime }[n]$ .To one's relief, several optimization algorithms could be applied to ease this downgrade and the one we leverage is the simulated annealing (SA) [29],which occasionally allows the selection of a less optimal solution during iterations, thereby enabling the algorithm to escape local optima. As for VbPWM, the SA scheme is largely simplified to occasionally fever the election of longer path when updating the survival path,i.e.,

$$p_{i}^{(j)}[n]=\left\{\begin{array}{l}p_{a(x)}^{(j-1)}[n],\left|l_{a(x)}^{(j-1)}\right|<\left|l_{b(x)}^{(j-1)}\right|\&u_{i}^{(j)}>t_{i}^{(j)}\\
p_{b(x)}^{(j-1)}[n],\left|l_{a(x)}^{(j-1)}\right|<\left|l_{b(x)}^{(j-1)}\right|\&u_{i}^{(j)}<t_{i}^{(j)}\\
p_{b(x)}^{(j-1)}[n],\left|l_{b(x)}^{(j-1)}\right|<\left|l_{a(x)}^{(j-1)}\right|\&u_{i}^{(j)}>t_{i}^{(j)}\\
p_{a(x)}^{(j-1)}[n],\left|l_{b(x)}^{(j-1)}\right|<\left|l_{a(x)}^{(j-1)}\right|\&u_{i}^{(j)}<t_{i}^{(j)}\end{array}\right.$$

(21)

whereui(j)\;U(0,1)is an uniformly distributed random variable for node j in iteration i and ti(j)∈[0,1]is the

<!-- Authorized licensed use limited to: Nanjing University of Information Science and Technology. Downloaded on September 03,2025 at 07:16:48 UTC from IEEE Xplore. Restrictions apply. -->

<!-- XIAN et al.: VbPWM-BASED ADT: ANITERATIVE DEDUCTION APPROACH RESTRICTING THE TRAVERSAL OF MPWM 4201 -->

threshold. For simulations performed in Section III-B the probability threshold is set as

$$t_{i}^{(j)}=\frac {1}{2\left(i-l_{m}\right)}\tag{22}$$

Though the threshold could and should be further optimized toward better performance, this improvement has currently fallen out of the current interest of presenting the feasibility of escaping the local optimum for the VbPWM scheme.

Based on the proposed iteration instant and the simplified SA, in the following Section III-B, fixed points simulations are conducted to verify the performance of the proposed scheme.

## B. Simulation Evaluation of the VbPWM

Due to the local nature of $\tilde {p}^{\prime }[n],$ ,the proposed scheme experiences a performance decrease in a degree compared with the MPWM, therefore in the following Section III-B1and Section III-B2, fixed-point simulations are performed to address this degradation.

Specifically, in this simulation stage, the degradation will be evaluated from two perspectives, where the first one is the modulation error in (24) for all complex input y under a given carrier frequency and the other one is the in-band SNR or EVM loss. Additionally, the complex input y is described in the Descartes coordinate other than the polar coordinate expression in [25], and a total of 24 bits are utilized to represent the input with 12 bits for real parts I and 12 bits for imaginary parts Q. To further restrict the complexity, magnitude computation of path lengths in (15) is determined through an approximation technique as

$$|I+jQ|\approx \max (|I|,|Q|)+\min (|I|,|Q|)/4\tag{23}$$

according to [30], where the divided-by-4 is reached by bit shift.

1) Evaluation of IF Quantization Noise: As stated in the original work of [25],the noise analysis model of MPWM-type LUT-based ADT consists of an IF quantizer, an upconversion module,and an RF quantizer, among which the IF quantizer affects the in-band SNR of the signal greatly. Accordingly, the IF quantizer performs the aforementioned mapping from the input signal y to the modulated signal qi ,which is always optimal due to its traversal process, therefore the IF quantization noise mainly consists of the difference between y and the closest qii(or $\tilde {q}$ ,computed from (6) using $\tilde {p}[n]$  ),i.e. $|y-\tilde {q}|$ . However, due to the limited memory length,the proposed scheme failed to match the corresponding $\tilde {q}$  but with the other qe (computed from (6) using the VbPWM's output sequence $\left.\tilde {p}^{\prime }[n]\right)$ ,accordingly introducing mismatch error $\Delta q=\tilde {q}-q_{e}.$ While the upconversion module and RF quantizer are shared between the original LUT-based ADT and the VbPWM, we think it is reasonable to deem this mismatch errorΔqas the main source of the additional noise compared with the original **MPWM.**

To evaluate the aforementioned IF quantization noise, the difference term $|y-\tilde {q}|$  and $|y-\tilde {q}-\Delta q|$  are leveraged as

<!-- 1 0.5 -10 -20 14 0 m -30 -0.5 -40 -1 -1 0 1 Re{y} -->
![](https://web-api.textin.com/ocr_image/external/5081b5a065c89a3c.jpg)

<!-- 1 0 0.5 -10 Im(y) 客트 0 -20 -0.5 -30 -40 -1 0 1 Re{y} -->
![](https://web-api.textin.com/ocr_image/external/f1840c4e71da40ba.jpg)

(a) (b)

<!-- 1 -10 0.5 -20 S트 0 -30 -0.5 -40 -1 0 1 Re{y} Re{y} -->
![](https://web-api.textin.com/ocr_image/external/b97be714630128f7.jpg)

<!-- 1 0.5 -10 Im(y) 0 -20 -0.5 -1 -30 -1 0 1 Re{y} -->
![](https://web-api.textin.com/ocr_image/external/d7c0c43beca7fc51.jpg)

(c) (d)

Fig.5. Simulated IF quantization noise over the complex plane for proposed VbPWM and MPWM. The carrier frequency is 1 GHz for (a),(b),and (c). The memory length for(b) and (c) is 3. The carrier frequency is 4 GHz for (d). (a) [25] whereN=16(b)VbPWM whereN=16;(c) VbPWM whereN=64;(d)[25]whereN=16. All necessary scalings are removed.

indicators, whose detailed computation is presented as follows:

$$e=10\log _{10}\left(\frac {\left|y-\frac {1}{N}\sum _{n=0}^{N-1}(2p[n]-1)e^{-j2\pi f_{c}T_{RF}n}\right|}{|y|}\right)$$

(24)

As for MPWM, the p[n] in (24) is its stored sequence $\tilde {p}[n]$ ,and correspondingly $e=|y-\tilde {q}|$ .As for VbPWM,the p[n] is the less optimum solved by the modulator and therefore $e=\left|y-q_{e}\right|=|y-\tilde {q}+\Delta q|$ . To visualize this noise, for each y whose real and imaginary part is within the range[-1,1],a related difference term e is computed to form the heatmaps inFig.5.

The IF quantization noise should be significantly lower if the input y is closer enough to any qi in the set Q according to the noise's definition. Additionally, the heatmap in Fig. 5a shows the same pattern with the firsttype Q(Q1#) in [25], which further suggests this statement. On the other side, though the VbPWM is configured with the same carrier and IF frequency as MPWM's, the generated heatmap presents an obvious rise in IF quantization noise for input whose amplitude is larger than approximately 0.8. Moreover, for the area that possesses less quantization noise, a distorted shape is witnessed compared to Fig. 5a, and we believe this is the outcome of the mismatch error Δq.

Additionally, as an increase in sequence length (the param-eter N in [25]) will accordingly enhance the system's SNR performance [25], the related quantization noise is presented in Fig. 5c as a comparison to Fig. 5b. A more compact and dense circle is witnessed in the presented heatmap for VbPWM underN=64,,while the region of input possessing less noise still requires the amplitude to be lower than approximately 0.8. Therefore, a scaling factor of 0.8 is recommended to be applied

<!-- Authorized licensed use limited to: Nanjing University of Information Science and Technology. Downloaded on September 03,2025 at 07:16:48 UTC from IEEE Xplore. Restrictions apply. -->

<!-- 4202 IEEE TRANSACTIONS ON CIRCUITS AND SYSTEMS-I: REGULAR PAPERS, VOL. 72, NO. 8, AUGUST 2025 -->

<!-- 40 30 S 20 PuE드 10 LUT-based -VbPWM N=16,Im=3 VbPWM N=64. im-3-4-VbPWM N=16,Im=2 0 VbPWM N=64,im=2 6 7 Frequency(Hz) 10 + -->
![](https://web-api.textin.com/ocr_image/external/4435f6b6df808340.jpg)

(a)

<!-- N=16 without SA N-64 without SA - N=16 with SA N=64 with SA 35 (Bp)HNGS PuEG드 30 25 20 2 6 Frequency(Hz) \begin{array}r109\end{array} x -->
![](https://web-api.textin.com/ocr_image/external/52174b7ca71664d1.jpg)

(b)

<!-- basod -VbPWM N=64,Im=3 35 VbPWM N=16,Im-3 -VbPWM N-64,Im=2 VbPWM N=16,lm=2 (BP)HNS 30 25 PUI드 20 15 10 0 2 6 Frequency(Hz) x109 -->
![](https://web-api.textin.com/ocr_image/external/56bfbd14adca1645.jpg)

(c)

<!-- 64QAM for VbPWM 64QAM for LUT-based ADT 102 102 OFDM-16QAMforVbPWM - OFDM-16QAMforLUT-base d ADT 00 EVM （迟IE 101 -x 10° 100 0 2 6 Frequency(Hz) \begin{array}r109\end{array} x -->
![](https://web-api.textin.com/ocr_image/external/4872cf0d1ad8ed4e.jpg)

(d)

Fig. 6. Simulated in-band SNR or EVM for the MWPM and VbPWM ADT. The SNR is calculated symbol-wise according to its EVM after recovering from the over-sampled baseband. The scaling factor and sequence length changes for LUT-based ADT at certain carrier frequencies in [25] are neglected for uniformness. (a) SNR simulation considering memory lengthlmat the symbol rate of 5 MBaud; (b) SNR simulation considering the involvement of SA at the symbol rate of 5 MBaud; (c) SNR simulation with SA's involvement at the symbol rate of 25 MBaud. (d) EVM simulation under higher order of modulation (64QAM) or OFDM. OFDM is set up with 20 sub-carriers, where two carriers on each side are assigned as null-carrier for protection.

to the VbPWM's input for suppressing IF quantization noise. By comparing Fig. 5c and Fig. 5a, no obvious improvement is witnessed for the VbPWM against the original work if the output length is enlarged, therefore a detailed simulation analysis considering in-band SNR is needed for the proposed scheme, which is presented in the following Section III-B2.

2) Evaluation of in-Band SNR: The in-band SNR in this section is calculated symbol-wise using an over-sampled receiver model. Specifically, as for most receivers, an over-sampled baseband signal is preferred toward less in-band quantization noise and less aliasing on the baseband signal. Therefore, SNRs and EVMs measured through the over-sampled baseband signal are more likely to interpret the performance of the proposed modulator in actual applications. To ensure an adequate over-sample rate in simulations,the baseband sample rate fBB is set as 250 Msps while the symbol rate for 16QAM modulated baseband signal is either 5 MBaud or 25 MBaud with the roll-off factor being 0.5. The sample rate for the 1-bit sequence is 16 Gbps, and two optional sequence lengths are provided as 16 bits and 64 bits, while 16 bits sequence is compatible with both the MPWM and VbPWM, but 64 bits sequence is exclusively handled by the VbPWM. Additional scaling on the IF complex samples is suggested in [25] towards better EVM, where this scaling value is set as 0.8 for the LUT-based ADT and 0.5 for the VbPWM ADT during simulation individually.

The assumed digital receiver receives the RF signal and converts the 1-bit sequence down to the baseband at the sample rate of 16 Gsps, decimating the IQ sequence from 16 Gsps to the inter-frequency sample rate of 1 Gsps with an 8-order Chebyshev Type I infinite impulse response (IIR) as an anti-aliasing filter. Afterward, the IF sequence is filtered and decimated to 250 Msps with an FIR filter whose pass-band and stop-band bandwidth are 75 MHz and 100 MHz respectively. The EVM is then measured from the recovered baseband sample, and the in-band SNR is consequently calculated from the measured EVM [31] as

SNR(dB)=-5.8-20log10(EVM(%)) (25)

where the coefficient 5.8 is the measured Peak-to-Average Power Ratio (PAPR) for 16QAM symbols.

The primary concerns for the ADT include SNR vari-ation related to different carrier frequencies and the SNR loss caused by the worsened IF quantization noise for the proposed scheme. Therefore, simulations considering carrier frequency are scheduled for both the VbPWM ADT and the typical MPWM-type LUT-based ADT, where carrier frequency increases from 0.5 GHz to 7.5 GHz with the step of 0.5 GHz to compute in-band SNRs for different frequencies. The sim-ulation results are presented in Fig. 6.

As discussed in Section II and Section III-B1, the perfor-mance of the proposed scheme may be influenced by different memory lengthslmand sequence lengths N,accordingly the simulations in Fig. 6a are conducted to quantify this influence. As depicted, significant degradation in SNR is observed for the simulated MPWM at specific frequencies, with a minimum occurring at a carrier frequency of 4 GHz. This is due to the limited value for $\frac {1}{N}^{-j2\pi _{c}T_{RF}n}$ at certain carriers and RF sam-ple rates, which is addressed by [25]asQ2#.As an example in this case, only four values are presented to construct the elements in $\mathcal {Q}:\frac {1}{N}+0i0+\frac {1}{N}i-\frac {1}{N}+0$ and $0-\frac {1}{N}$ ,and the corresponding reduction in the element amount of Q leads to the increased quantization noise, as presented in Fig. 5d when compared to Fig. 5a. To compensate for this loss in performance at certain carrier frequencies, it is suggested to extend N to a value such as 32, but this extension is not mentioned in the hardware implementation, and therefore we prefer not to take these approaches in this section for the uniformness of simulation.

As presented in Fig. 6a, a nearly 15 dB enhancement in SNR is witnessed when the sequence length is extended from 16 to 64,but still, the in-band SNR is up to 10 dB less than the MPWM-type LUT-based ADT even with sequence extension.Meanwhile, with the enlarged memory length from lm=2tolm=3,,the SNR increases by a maximum of 7dB for N=16and 4 dB forN=64. In contrast, for most frequencies, the increase of memory length yields only minor improvements in in-band SNR, and therefore the cost-effectiveness for enlarging memory length should be evalulated in practical applications to determine if a 2-3 dB SNR gain is worth doubling resource consumption. On the other hand, by adopting a higher order of modulation (i.e. 64QAM), the simulated EVM will not vary largely com-pared with 16QAM, as the results presented in Fig. 6d show that simulated EVMs are around 1% for the proposed scheme.

<!-- Authorized licensed use limited to: Nanjing University of Information Science and Technology. Downloaded on September 03,2025 at 07:16:48 UTC from IEEE Xplore. Restrictions apply. -->

<!-- XIAN et al.: VbPWM-BASED ADT: AN ITERATIVE DEDUCTION APPROACH RESTRICTING THE TRAVERSAL OF MPWM 4203 -->

While the extension of memory length seems costly,imple-menting SA might be a better solution for higher in-band SNR, which is shown in Fig. 6b. The adoption of SA leads to an SNR increase of less than 6 dB for all simulated frequencies when N=16,,but forN=64implementing SA decreases the SNR at carrier frequencies of 6.5 GHz and 7 GHz while providing an enhancement of less than 3dB for other frequencies.

With the enlarged memory length and modified SA adopted, the simulated SNRs for VbPWM under larger bandwidth are presented in Fig. 6c where the symbol rate is extended from 5 MBaud to 25 MBaud. For the MPWM, the in-band SNR decreases near 10 dB for most frequencies after the extension of the signal's bandwidth compared with Fig. 6a, except for the carrier frequency at 4 GHz. The degradation of SNR forN=16turns out to be nearly 15 dB, while for situation N=64,,the SNR decreases by less than 7 dB. By comparing the proposed scheme and MPWM,the proposed scheme still performs worse than MPWM for most frequencies but the SNR loss is reduced from 10 dB in Fig. 6a under 5 MBaud to less than 5 dB under 25 MBaud. Due to the high PAPR value, the constant scaling for the proposed method will lead to a downgrade in EVM as the current amplitude normalization is performed by scaling the input sample according to its maximum amplitude, therefore an increased EVM is presented in Fig. 6d even compared with the 25-MHz simulation in Fig. 6c.

In general, the conducted simulations in this section have proven that the proposed scheme successfully produces an approximate $\tilde {p}[n]$  without any traversal process, therefore easing the pre-process's complexity in real applications. In addition, to verify the practical1 performance of the proposed VbPWM, in Section IV the implementation structure of the VbPWM modulator is discussed and is utilized within the ZCU102 from Xilinx to measure its SNR and EVM over hardware.

# IV. HARDWARE VERIFICATION OF THE VBPWM

## A. Implementation Structure of VbPWM Modulator

According to the overall structure of VbPWM-based ADT inFig. 3 and its iteration instance, the input of the modulator is the baseband complex sample and the output should be the N-bit binary sequence after N+1 times of iterations. Furthermore, considering the streaming input of the complex sample, the modulator should be able to deduce the output continuously, i.e., generating a valid output sequence at each clock period with proper latencies. Given these guidelines, loops are unfolded and iterations are pipelined to form the presented structure in Fig. 7 whose N=64 and lm= 2. Specifically, a total of 4 nodes are involved between iterations, at the same time, the related four survival paths along with their path length are passed between iterations, as denoted by the p(i)l(i)(I) and l(i)(Q). For ease of expression and coding, survival paths are concatenated as p(i)={p3(i)[]p2(i)[]p1(i)[]p0(i)}[]. (i)(I)is the in-phase part (or real part) of the path length andl(i)(Q) is the quadrature (or imaginary) part, which are both concatenated from the four survival paths'lengths in the same manner withp(i)

<!-- Pre-SUB Unit Iteration Iteration Iteration Convergence Unit 0 Unit 1 Unit 61 Unit y1 \stackrelp(2)1 100 p(2) 10 0.6 0O0 2 {}伞 100 Look $\begin{array}{l}p^{(60)}\\ hline\end{array}$ I(2)(I) l(3)(I) I(0)(I) l(64)(I) F0 p[n] \stackrely0⇒ \;P\; → 0.00 → A ΔAB → $\textcircled {4}$ I(2)(Q) KOH \stackrelI(t)(Q)⇒ I(4)(Q) I(64)(Q) D ↓ 3 InitEvec ↑ EVec[2] ↑) EVec[3] ↑EVec[3) ↑ EVec[63] EVec Storage -->
![](https://web-api.textin.com/ocr_image/external/1148de28b171cdd5.jpg)

Fig. 7. Overall structure of the VbPWM modulator.

To compute path lengths with a reduced adder consumption, the proposed structure leverages the survival path length from previous iterations to compute the length of possible paths. For instance, the computation of the possible path lengthla(0)(i) is denoted as

$$l_{a(0)}^{(i)}=y-\frac {1}{N}\sum _{n=0}^{i+1}p_{a(0)}^{*(i)}[n]e^{-j2\pi f_{c}T_{RF}n}\quad \stackrel {(a)}{=}l_{a}^{(i)}-\frac {1}{N}\left(2p_{a(0)}^{(i+1)}[i]-1\right)e^{-j2\pi f_{c}T_{RF}i}\tag{26}$$

and accordingly, the length calculation is broken down accord-ing to (a) in (26), involving the path lengthla(0)(i)from iteration i. Therefore, the computation is simplified from a series of additions to a single addition but the computed survival path lengths should be passed to the coming iteration for further process. Another element in (26) is the exponential value -j2πfcTRFi,which is computed and stored in advance. In the following discussion, we use the term EVec to denote the exponential vector formed by the mentioned exponential value fromi=0toi=63.

Four essential modules are included in this ADT design shown inFig. 7, which are the Pre-SUB Unit, the Iteration Unit, the Convergence Unit, and the EVec Storage. The functions of these modules are described as

·Pre-SUB Unit: performing iterations 0, 1, and 2;

·Iteration Unit: performing single iteration for iteration 3 to iteration 64;

·Convergence Unit: performing comparison on all node's survival paths;

·Evec Storage: storing the InitEvec and Evec for comput-ing path lengths.

Detailed descriptions are provided in the following sections.

1) Pre-SUB Unit: By reviewing the trellis graph in Fig.4whenlm=2,, deterministic expressions exist for the survival paths' length before iteration 2 as all nodes receive only one path, and by the end of iteration 2 all survival path lengths are initialized according to

$$l_{0}^{(2)}=y+\frac {1}{N}+\frac {1}{N}e^{-j2\pi f_{c}T_{RF}}$$

$$l_{1}^{(2)}=y+\frac {1}{N}-\frac {1}{N}e^{-j2\pi f_{c}T_{RF}}$$

$$l_{2}^{(2)}=y-\frac {1}{N}+\frac {1}{N}e^{-j2\pi f_{c}T_{RF}}$$

$$l_{3}^{(2)}=y-\frac {1}{N}-\frac {1}{N}e^{-j2\pi f_{c}T_{RF}}\tag{27}$$

<!-- Authorized licensed use limited to: Nanjing University of Information Science and Technology. Downloaded on September 03,2025 at 07:16:48 UTC from IEEE Xplore. Restrictions apply. -->

<!-- 4204 IEEE TRANSACTIONS ON CIRCUITS AND SYSTEMS-I: REGULAR PAPERS, VOL. 72, NO. 8, AUGUST 2025 -->

<!-- Pre-SUB Unit I-Subtractor Interleaver S B 48bit l(2)(I) InitEVec[0](I) A S yI B1 12bit InitEVec[1](I) A S 12bit B1 InitEVec[2](I) A S Interleaver 64'd0 B1 64'd0 InitEVec[3](I) 'd1 256bit 256bit p(2) Q-Subtractor 64'd2 A S 64'd3 B InitEVec[0](Q) A S yQ B1 InitEVec[1](Q) Interleaver A S 12bit 48bit l(2)(Q) l(2)(Q) B1 InitEVec[2](Q) A S B 12bit InitEVec[3](Q) 12*4bit 12*4bit InitEVec[3:0](I) InitEVec[3:0](Q) -->
![](https://web-api.textin.com/ocr_image/external/7f7bb371ebba4d0c.jpg)

Fig. 8. Implementation structure of the Pre-SUB unit.

Therefore, the Pre-SUB Unit in Fig. 8 is placed to accom-plish iteration 0 to 2, in other words, directly computing the survival path lengths for iteration 2. The unit's input is the complex sample separated into its real part yI and imaginary part yQ, each quantized to 12-bit. The InitEVec is also provided to support path length calculation,which is the combination of $\frac {1}{N}$  and $\frac {1}{N}e^{-j2\pi f_{c}T_{RF}}$ shown in (27). Accordingly, InitEVec[0](I) in Fig. 8 represents the real part of the EVec combination used for computingl0(2,i.e., $\text {Ii}\text {EV}[0](I)=\text {Ral}\left\{\frac {1}{N}+\frac {1}{N}^{-j2\pi _{}T_{RF}}\right\}$ and the same applies to the imaginary part. The computed real and imag-inary survival path lengths are respectively quantized with 12 bits for 4 nodes and afterward concatenated into the 48-bit length groupsl()(I)andl()(Q), along with the 256-bit sur-vival path groupsp(2)={p3(2)[n].p2(2)[n]p1(1)[n].p0(0)[n]}= {64'd3,64'd2,64'd1,64'd0}.

2) Iteration Unit: Each Iteration Unit selects the survival path and its corresponding length from the previous unit to generate and forward possible paths. After computing the length for each possible path, the one with a shorter length is registered as the node's survival path. The implementation structure of the iteration unit is shown in Fig. 9.

Specifically, the unit takes all survival paths and path lengths (i)(I)(i)(Q)anp(i)from the previous iteration unit or pre-SUB unit, then de-interleaves them as the survival path and the related length in iteration i for each node. Afterward, the possible path generation is performed inside the interconnect module, adding one bit to the end of all survival paths to generate two possible paths (i.e.,p0(0)(i)[n]and.p0(1)(i)[n]).Each possible path is then dispatched to its termination node along with its original survival path length (i.e.,l0(i).Dispatch of possible paths results in four nodes (node 0, node 1, node 2, and node 3) individually receiving a group of signals, each containing two possible paths and the original path lengths from the source node. In the presented case wherelm=2, node 0 receives the possible paths from node 0 (path.p0(0)(i)[n]) and node 2 (path .p2()(i)[n])as the least two significant bits for these paths are {0,0}, which corresponds to the binary expression of node 0. Similarly,node 1 receives the possible paths from node 0 (pathp0()(i)[])and node 2 (path .p_{2(1)}^{(i)}[n]\right) as the least two significantbits for these paths are {0,1}, corresponding to the binary expression of node 1. Similarly, node 2 receives possible paths from node 1 (path.p1(0)(i)[]) and node 3 (path.p3(0)(i)[n]), and node 3 receives possible paths from node 1 (path.p1(1)(i)[n])and node 3 (path .p3(1)(i)[n])

For situations wherelm≠2,,we let node 0 receive two possible pathspa(0)(i)andpb(0)(i) from node a and node b along with survival path lengthsa(i)andlb(i). The length calculation and survival path update are carried out independently for four nodes, and only the process for node 0 is presented in Fig.9.Firstly, the path lengths for the two possible paths are computed according to (26) using a 12-bit adder with an inner stage of register. As in (26) the LSB ofp(0(i[]is involved, an add-sub control port is utilized for the adder to determine whether performing an add-operation or a sub-operation on the original path lengthl(i)with theEVec[i]=e-j2πfcTRFi To accommodate the register-enabled adder, an additional stage of registers is inserted for the pathspa(0)(i)[n]andpb(0)(i)[]. After computing the length for each possible path, the path length's magnitude is calculated according to (23),where the first stage of finding the maximum or minimum is performed immediately after the adder as

maxIQa=max{la(0)(i)(I),la(0)(i).(Q)} $\min IQ_{a}=\min \left\{l_{a(0)}^{(i)}(I),l_{a(0)}^{(i)}(Q)\right\}$ 

(28)

and the second stage performs a shifted (right shifted by two on minI.Qa)addition operation using the registered first stage's output as

$$Abs_{a}=\max IQ_{a}+\min IQ_{a}»2.\tag{29}$$

Afterwward, the magnitudes of paths pa(0)(i)[n]andpb(0)(i)[n] are compared. The path and corresponding length with the smaller magnitude are selected within MUXs as node 0'ssurvival path p0(1×1) and lengthl0(i+1)for iterationi+1.At the end of this unt, an interleaver is placed to combine the survival paths and lengths from the four nodes, generating48-bi(i+1)(I),48-bit l(i+1)(Q)and256-bitp(i+1)as input for the next iteration unit.

It can be inferred from the structure that the number of valid bits inp(i)gradually increases with each iteration, as the survival path in iteration i only contains i valid bits. Therefore, an optimal structure could be considered to present an elastic

<!-- Authorized licensed use limited to: Nanjing University of Information Science and Technology. Downloaded on September 03,2025 at 07:16:48 UTC from IEEE Xplore. Restrictions apply. -->

<!-- XIAN et al.: VbPWM-BASED ADT: AN ITERATIVE DEDUCTION APPROACH RESTRICTING THE TRAVERSAL OF MPWM 4205 -->

<!-- Iteration Unit pω(0)[0] (1) (1) 2bit N 1(D) Group 0 (I) (1) 12bit (Q) IcW(I) maxIQ, maxIQ3 x C( 2bit $\textcircled {6}$ EVecl 0 Pr0(0)[0] ABS p0′′[a p.[a] (Q) I*ω(Q) MAX minIQ2 , B Abs. Abs4 CMP- 64bit \stackrell′′(I)⇒ 176bit (Q) +MIN l′′(Q) C) It0+D(1) 48bit l(i+1)(I) 48bit 1(1) INTE e0 [n] 12bit EVec[(Q) (1) REG psu(i)[n] C l(0)(Q 64bit RE +(I) I2n+1/(I) 48bi l(i+1)(Q) 48bit I(1) REG RC (Q) REG REG -PLo(0)[0] t 0 N Rm′0[n] (1) REG REG REG C(1) G CQ N 12bit maxIQ, S ABS \stackrelp(0)longrightarrow 256bit E EVec[i](1) C \;pww(l)[0 MAX minb lQ, Abs 000 I(1) Group 1 MIN pcc(0)[n] 1 Psα+D(I) 176bit (Q) T (Q) It0t0(Q) (Q) Group 2 176bit 12bit Group 3 176bit EVec[i](Q) pN0(1)[n] REG Ps,nf[n] 64bit v Possible Path EVec[i](1) EVec[i](Q) Input De-interleave Generation & Output Interleave Receiving Path Length Calculation and Survival Path Update -->
![](https://web-api.textin.com/ocr_image/external/ce54f46e034989e8.jpg)

Fig.9. Implementation structure of the iteration unit.

<!-- Convergence Unit , Abss maxlQ, (0 MAX MIN \stackrelI*0(I)⇒ 48bis maxIQ +CMP minIQ Abs1 MIN P2(0)[n] e \stackrelIse(Q)⇒ REG REG maxIQ REG REG REG REG \widetildep[n] MAX [a] \stackrelp(60)⇒ 256bit maxIQ Abs MAX -->
![](https://web-api.textin.com/ocr_image/external/ecfc6dbf28ee5e0e.jpg)

Fig. 10. Implementation structure of the convergence unit.

width forp(i)'sregisters and here we let the IDE do this when implementing.

3) Convergence Unit: The convergence unit is placed at the end of the iteration pipeline to select the survival path with the least path length from the last iteration. The structure in Fig.10resembles that of the Iteration Unit, including the former de-interleaving and magnitude calculation. The Convergence Unit directly computes magnitudes of survival path lengths for all nodes, and a two-stage comparison is conducted to elect the corresponding survival path with the least path length from four nodes as the output $\tilde {p}^{\prime }[n].$ 

4) EVec Storage: As the computation of path lengths in both the Iteration Unit and Pre-SUB Unit involves the complex vector -j2πfcTRF,this N-length complex vector is pre-generated and stored in the EVVec Storage unit using registers. Each entry in the complex vector's real and imaginary parts is individually quantized and stored using 12 bits. For the Pre-SUB Unit, the provided InitEVec[3:0] is a combination of the values $\pm \frac {1}{N}\pm \frac {1}{N}^{-j2\pi f_{c}T_{RF}}$ in its real and imaginary part. As for the Iteration Unit, the provided EVec[i] is the value $\frac {1}{N}^{-j2\pi f_{c}T_{RF}i}$  denoted by its real and imaginary part. Real-time re-configuration can be performed by flushing the stored values inside the EVec Storage with the new EVec[i] corresponding to the new carrier frequency.

TABLE II

RESOURCE CONSUMPTION OF THE VBPWM-BASED ADT

<table border="1" ><tr>
<td>Type</td>
<td>Used</td>
<td>Total</td>
<td>Ratio</td>
</tr><tr>
<td>CLB LUTs</td>
<td>58,426</td>
<td>274,080</td>
<td>28%</td>
</tr><tr>
<td>CLB Registers</td>
<td>121,523</td>
<td>584,160</td>
<td>20.8%</td>
</tr><tr>
<td>CARRY8</td>
<td>5,739</td>
<td>342,620</td>
<td>1.68%</td>
</tr><tr>
<td>BRAM</td>
<td>1</td>
<td>912</td>
<td>&lt;1%</td>
</tr><tr>
<td>DSP</td>
<td>98</td>
<td>2,520</td>
<td>3.65%</td>
</tr><tr>
<td>GTHE4</td>
<td>1</td>
<td>24</td>
<td>4.17%</td>
</tr></table>

## B. Implementation Results

Based on the presented VbPWM modulator, we construct a fully serialized and runtime reconfigurable VbPWM-based ADT using Zynq Ultrascale+ ZCU9EG from XILINX on the ZCU102 evaluation kkit according to the systematic structure in Fig. 3. Four Gold sequence generators are utilized as the information source for the latter 16QAM modulation, and the polynomials for each generator are determined according to

$$g_{0}(x)=x^{3}+1,g_{1}(x)=x^{3}+x^{2}+x^{1}+1\tag{30}$$

The 32-bit LFSR under g0(x) is initialized with a seed value of 32'd1 for all generators. The LFSR under g1(x) is initialized with the seed value of 32'd114, 32'd514,32'd1919, and 32'd810 for the four generators respectively. Afterward, through a raised cosine filter with a roll-off factor of 0.5 the signal is upsampled from the baseband symbol rate to fIF.The complex sample is then sent to the VbPWM unit in Section IV-A to deduce a 64-bit sequence, which is serialized within the on-board GTH at the rate of 16 Gbps. Additionally, a virtual input-output (VIO) is applied to update the registers in EVec Storage unit for run-time reconfiguring the carrier frequency.

The resource consumption of the VbPWM-based ADT is presented in Table II, along with the comparison between several recent ADT structures in Table III. The BRAM con-sumption of the VbPWM-based ADT is tremendously reduced compared with all the listed work, no matter whether the work utilizes MPWM and the LUT-based technique or not.

<!-- Authorized licensed use limited to: Nanjing University of Information Science and Technology. Downloaded on September 03,2025 at 07:16:48 UTC from IEEE Xplore. Restrictions apply. -->

<!-- 4206 IEEE TRANSACTIONS ON CIRCUITS AND SYSTEMS-I: REGULAR PAPERS, VOL. 72, NO. 8, AUGUST 2025 -->

<!-- -40 60 -50 80 -60 2.9 3 3.1 3.2 3.3 (uBp) Dwod -70 x10° -80 -90 0 2 6 8 Frequency(Hz) x109 -->
![](https://web-api.textin.com/ocr_image/external/89607bbf944d461d.jpg)

(a)

<!-- -30 5M -40 25M 50M -50 (uBp) J0od -60 -70 -80 3.46 3.48 3.5 3.52 3.54 Frequency (GHz) -->
![](https://web-api.textin.com/ocr_image/external/547738f9d4d32edc.jpg)

(b)

<!-- 1 5M 25M 50M Ideal 0.5 2nEJpenO 0 -0.5 -0.5 0 0.5 In-phase -->
![](https://web-api.textin.com/ocr_image/external/19b2e626d4bc3fbd.jpg)

(c)

<!-- 10 5M- 25M 50M 8 .. 6 00 WAE 0 1 00 00 0d 000000 2 b0000 090 0 2 6 8 Frequency (Hz) x109 -->
![](https://web-api.textin.com/ocr_image/external/2e4f9de586d2ba37.jpg)

(d)

Fig. 11. Implementation results. Thespectra are measured with Keysight N9020B. The constellations and EVMs are measured with FSW67 from Rohde & Schwarz (a) Power spectrum with a 20 MBaud symbol rate. The carrier frequency of the ADT is set as 3.1 GHz. The frequency span is set as 8 GHz for the main figure and 50 MHz for the sub-figure. The RBW is set as 100 KHz and the VBW is set as 1 KHz for the full span figure. The RBW is set as 30 KHz and the VBW is set as 300 Hz for the scaled figure. (b) Measured spectrum with different symbol rates. The carrier frequency of the ADT is set as 3.5 GHz. The frequency span is set as 100MHz, the RBW is set as 20 KHz and the VBW is set as 20 Hz. (c) Measured constellation with different symbol rates. The carrier frequency is 3.5 GHz. An ideal 16QAM constellation is provided as a reference. (d) Measured EVM with different symbol rates. The frequency step is 250 MHz.

TABLE III

COMPARISON OF RESOURCE CONSUMPTION WITH

OTHER ADT STRUCTURES

<table border="1" ><tr>
<td>Type</td>
<td>VbPWM</td>
<td>Dual-band<br>LUT [27]</td>
<td>1GHz<br>DSM[17]</td>
<td>DSM<br>LUT [28]</td>
</tr><tr>
<td>LUTs</td>
<td>58,426</td>
<td>6,683</td>
<td>487,882</td>
<td>395</td>
</tr><tr>
<td>Registers</td>
<td>121,523</td>
<td>7,382</td>
<td>482,427</td>
<td>N/A</td>
</tr><tr>
<td>BRAM</td>
<td>1</td>
<td>510</td>
<td>258</td>
<td>114</td>
</tr><tr>
<td>DSP</td>
<td>98</td>
<td>88</td>
<td>1,461</td>
<td>0</td>
</tr><tr>
<td>GTHE4</td>
<td>1</td>
<td>1</td>
<td>1</td>
<td>1</td>
</tr></table>

N/A represents not appliable or not mentioned in the original work;

Moreover, the sole BRAM usage in the VbPWM-based ADT is the result of an asynchronous FIFO utilized for transmitting the sequence from the modulator clock domain to the GTH clock domain. On the other hand, DSPs are utilized only for constructing the raised cosine filter and generating the carrier, while all the mentioned adders in the VbPWM modulator are built by the CLB resource, resulting in a relatively large LUT usage. Registers are also extensively leveraged to buffer both related signals inside the pipelines, where the iteration unit at the very first consumes about 1000 CLB registers but the last iteration unit consumes more than 2500. Though the resource commparison sounds promising, we can merely suggest that the proposed work depicts an advantage in BRAM usage and the comparison to the listed state-of-the-art is not fully reliable, while [27] is a dual-band application, [17] provides 1-GHz of clean bandwidth, [28] uses far less LUT and registers using other modulation other than MPWM while the perfect candidate using LUT with MPWM [25] has not provided information on their resource statistics.

# C. Verification Results

The verification of the proposed **ADT** focuses on its output spectrum and EVM under different carrier frequencies and symbol rates, where the verification environment is shown in Fig. 12. The FPGA is connected to the host PC using a JTAG connection for bitstream programming and carrier frequency update, and the GTH's output is connected to the vector signal analyzer (VSA) with coaxial cables.

<!-- VSA Host PC SMA Cable FPGA JTAG -->
![](https://web-api.textin.com/ocr_image/external/6158dda69eecbad5.jpg)

Fig. 12. Hardware verification environment.

By setting the carrier frequency as 3.6GHz,the measured spectra with 5 MBaud of symbol rate with two different spans are given in Fig. 11a, where a series of harmonic disruptions are revealed around the target band, separated by a gap of 250 MHz. As the harmonic disruption is strongly correlated with phase disruption, these harmonics are possibly attributed to the inner phase jumps of the local optimal sequence, which is related to the enlarged IF quantization noise as it will introduce additional phase noise to the modulated signal compared with the MPWM. On the other hand, as the harmonic disruptions can be eased by leveraging external filters, the noise floor near the target band would offer the most in-band noise, thus in Fig. 11b we take a closer look into the ADT's in-band spectrum within a frequency span of 100 MHz under different symbol rates. The measured in-band noise floor for 5 MBaud is around -85 dBm and the noise floor for 25 MBaud is slightly higher than -85 dBm. Assuming the noise floor for the measured symbol rates is the same -85 dBm, Fig. 11b then illustrates a declining SNR due to the reduced power density at higher symbol rates.

To better verify the mentioned in-band SNR loss under different carrier frequencies, EVMs of the ADT at different levels of carrier frequency are calculated from its constellation using VSA in Fig. 12, where the constellation under 3.5 GHz is provided in Fig. 11c for visualization. A rotation on the received constellation is witnessed for all considered symbol rates, and it is hard to determine at this stage whether this rotation of constellations is the result of the quantization noise or the jitter of the oscillator driving the GTH's inner phase lock loop (PLL), which requires further investigation to verify.

<!-- Authorized licensed use limited to: Nanjing University of Information Science and Technology. Downloaded on September 03,2025 at 07:16:48 UTC from IEEE Xplore. Restrictions apply. -->

<!-- XIAN et al.: VbPWM-BASED ADT: AN ITERATIVE DEDUCTION APPROACH RESTRICTING THE TRAVERSAL OF MPWM 4207 -->

Afterward, the calculated EVMs under different carriers with different symbol rates are given in Fig. 11d, where 29 carrier frequencies are utilized in the range from 0.6 GHz to 7.6 GHz at the step of 250 MHz. A decrease in EVM is firstly presented at lower carrier frequencies,i.e.&lt;1.6 GHz,which is similar to the trend in [28]. After that, the EVM continues to rise with the increased carrier frequency. Additionally, a large variance of EVM after 5 GHz under 25 MBaud and 50 MBaud is witnessed. As the former fixed-point simulation has not suggested the existence of this peak, we consider this as an outcome of onboard or external disruption, which may come from certain band-limited noise or leakage of other instruments.

The increase in symbol rate from 5 MBaud to 25 MBaud correspondingly raises the EVM due to the enlarged quan-tify noise, and the EVM loss is downgraded to near 9% when the symbol rate is further extended from 25 MBaud to 50 MBaud. On the other hand, compared with the results listed in [25] for the LUT-based ADT, an approximate 1% loss is witnessed for 5 MBaud. As for the LUT-based ADT in [28],the measured EVM reaches 3% in its worst condition under 24.576 MBaud of symbol rate, which is still way better than the proposed scheme. While the simulated EVM (between 1% and 1.7%) in [28] is around the same range as that of VbPWM, the outperformance of this LUT-based ADT might be attributed to its external clock generator for driving ZCU102's gigabit transceiver, but for the proposed scheme this reference comes from an on-board oscillator (actually from the si570 on ZCU102). Compared with the multi-level PWM scheme, the harmonic suppression and EVM of VbPWM are significantly worse considering the output spectrum, while the 5-level PWM [19] reports an EVM of 1.7% under 16QAM and in [20] the EVM is reduced to 0.6% within a 5-level MPWM scheme, which makes the multi-level PWM a promising technique for further ADTs.

# V. CONCLUSION

Based on the current LUT-based ADT, in this paper, a VbPWM-based ADT is proposed according to the coding principle of MPWM, which substitutes the traditional LUT usage for storing pre-generated output sequences. With a Viterbi decoder-like modulator to iteratively deduce the output sequence,the proposed VbPWM-based ADT decreases the high RAM consumption and high pre-process complexity of the MPWM scheme. Based on the fixed point simulation, the deduced local optimum performs 10 dB worse than the global optimum of MPWM considering SNR, but this loss is further reduced to 8 dB by implementinga simplified SA. Afterward, a fully serial VbPWM-based ADT is designed and implemented on the ZCU102evaluation board, consuming 28% of LUTs and 21% of registers with no extra usage of RAM for the modulator. Verifications start by measuring the power spectrum of the proposed VbPWM-based ADT under different baseband symbol rates at 3 GHz,along with the corresponding EVM measured under the range of carrier frequencies from 0.6GHzto 7.6 GHz, where an increasing trend of EVM is witnessed with the growth of the carrier frequency.

Further research could focus on the improvement of the VbPWM scheme towards less resource consumption and higher in-band SNR. Additionally, various optimization algo-rithms, such as gradient descent, couldbe applied to refine the VbPWM scheme or address the optimization problem independently. Moreover, we suggest that external oscillators with good stability can be applied as a reference clock for the GTH further to investigate oscillators' impact on the ADT's performance.

# ACKNOWLEDGMENT

The authors wishto express their special thanks to Tianfu Qi and JJiyi Liu for their assistance when revising the manuscript.

# REFERENCES

[1] N. Zimmermann, B. T. Thiel, R. Negra, and S. Heinen, “System architecture of an RF-DAC based multistandard transmitter," in Proc. 52nd IEEE Int. Midwest Symp. Circuits Syst., Aug. 2009, pp. 248-251.

[2] J. Keyzer, R. Uang, Y. Sugiyama, M. Iwamoto, I. Galton, and P. M. Asbeck, "Generation of RF pulsewidth modulated microwave signals using delta-sigma modulation," in IEEE MTT-S Int. Microw. Symp. Dig., Aug. 2002, pp. 397-400.

[3] J. Mitola, "The software radio architecture,” IEEE Commun. Mag., vol. 33, no.5,pp. 26-38,May 1995.

[4] D.C.Dinis, R. F. Cordeiro, A. S. R. Oliveira, J. Vieira, and T. O. Silva, “A fully parallel architecture for designingfrequency-agile and real-time reconfigurable FPGA-based RF digital transmitters," IEEE Trans. Microw. Theory Techn., vol. 66, no. 3, pp. 1489-1499,Mar.2018.

[5] D. C. Dinis, R. F. Cordeiro, F. M. Barradas, A. S. R. Oliveira, and J. Vieira, "Agile Single- and dual-band all-digital transmitter based on a precompensated tunable delta-sigma modulator," IEEE Trans. Microw. Theory Techn., vol. 64, no. 12, pp. 4720-4730,Dec.2016.

[6] R.F. Cordeiro, A. S. R. Oliveira, and J. M. N. Vieira, "All-digital trans-mitter with a mixed-domain combination filter," IEEE Trans. Circuits Syst. II, Exp. Briefs, vol. 63, no. 1, pp.4-8,Jan.2016.

[7] M. Tanio, S. Hori, N. Tawa, T. Yamase, and K. Kunihiro, "An FPGA-based all-digital transmitter with 28-GHz time-interleaved delta-sigma modulation," in IEEE MTT-S Int. Microw. Symp. Dig., May 2016, pp.1-4.

[8] M. M. Ebrahimi, M. Helaoui, and F. M. Ghannouchi, "Delta-sigma-based transmitters: Advantages and disadvantages," IEEE Microw.Mag., vol.14,no.1,pp. 68-78,Jan.2013.

[9] H. Ruotsalainen, H. Arthaber, T. I. Laakso, and G. Magerl, "Quantization noise reduction techniques for digital pulsed RF signal generation based on quadrature noise shaped encoding," IEEE Trans. Circuits Syst.I,Reg. Papers, vol. 61, no. 9, pp. 2525-2536,Sep.2014.

[10] H. Ruotsalainen, H. Arthaber, and G. Magerl, "A new quadrature PWM modulator with tunable center frequency for digital RF transmitters," IEEE Trans. Circuits Syst. II, Exp. Briefs, vol. 59, no. 11,pp. 756-760, Nov.2012.

[11] K. Hausmair, S. Chi, P. Singerl, and C. Vogel, "Aliasing-free digital pulse-width modulation for burst-mode RF transmitters," IEEE Trans. Circuits Syst. I, Reg. Papers, vol. 60, no.2, pp. 415-427,Feb. 2013.

[12] T.Blocher and P. Singerl, "Coding efficiency for different switched-mode RF transmitter architectures," in Proc. 52nd IEEE Int. Midwest Symp. Circuits Syst., Aug. 2009,pp.276-279.

[13] J. I. Morales, F. Chierchie, P. S. Mandolesi, and E. E. Paolini, "A distortion-free all-digital transmitter based on noise-shaped PWM," IEEE Trans. Circuits Syst. I, Reg. Papers, vol. 70, no. 2, pp. 694-704, Feb.2023.

<!-- Authorized licensed use limited to: Nanjing University of Information Science and Technology. Downloaded on September 03,2025 at 07:16:48 UTC from IEEE Xplore. Restrictions apply. -->

<!-- 4208 IEEE TRANSACTIONS ON CIRCUITS AND SYSTEMS-I: REGULAR PAPERS, VOL. 72, NO. 8, AUGUST 2025 -->

[14] R.F. Cordeiro, A. S. R. Oliveira, J. Vieira, and N. V. Silva, "Gigasam-ple time-interleaved delta-sigma modulator for FPGA-based all-digital transmitters," in Proc. 17th Euromicro Conf. Digit.Syst.Design (DSD), Aug. 2014,pp.222-227.

[15] S. Hatami,M. Helaoui, F. M. Ghannouchi, and M. Pedram, "Single-bit pseudoparallel processing low-oversamplinng delta-sigma modulator suitable for SDR wireless transmitters," IEEE Trans. Very Large Scale Integr. (VLSI) Syst., vol. 22, no. 4, pp. 922-931, Apr. 2014.

[16] H. Li et al., “A 21-GS/s single-bit second-order delta-sigma modulator for FPGAs," IEEE Trans. Circuits Syst. II, Exp. Briefs, vol.66,no.3, pp. 482-486,Mar.2019.

[17] S. S. Pereira, L. F. Almeida, D. C. Dinis, A. S. R. Oliveira, P. P. Monteiro, and N. B. Carvalho, "Frequency-agile real-time all-digital transmitter with 1 GHz of bandwidth," IEEE Trans. Circuits Syst. II,Exp. Briefs, vol. 70, no. 8, pp. 2844-2848,Aug.2023.

[18] S. S. Pereira, L. Almeida, A. S. R. Oliveira, N. B. Carvalho, and P. P. Monteiro, "Improving coding efficiency in all-digital transmitters," in Proc. IEEE Radio Wireless Symp. (RWS), Jan. 2023, pp. 115-117.

[19] F.Yao,Q.Zhou, and Z. Wei, "A novel multilevel RF-PWM method with active-harmonic elimination for all-digital transmitters," IEEE Trans. Microw. Theory Techn., vol. 66, no. 7, pp. 3360-3373, Jul. 2018.

[20] S.Zeng,Q.Zhou, S. Yu, L. Zhu, and Z. Wei, "Harmonic elimination method of RF-PWM based on phase-shift control and MPWM for all-digital transmitters," in IEEE MTT-S Int. Microw. Symp. Dig., May 2023, pp.1-3.

[21] S.Y.Yang,J. Yang, J. Zhao, and X. Y. Zhang,“Clean bandwidth improvement of MPWM encoding method for RF all-digital transmitter," IEEE Trans. Circuits Syst. II, Exp.Briefs,vol. 68, no.7,pp. 2404-2408, Jul.2021.

[22] S. Chung, R. Ma, K. H. Teo, and K. Parsons, "Outphasing multi-level RF-PWM signals for inter-band carrier aggregation in digital transmitters," in Proc. IEEE Radio Wireless Symp. (RWS), Jan. 2015, pp.212-214.

[23] S. Chung, R. Ma, S. Shinjo, H. Nakamizo,K. Parsons, and K. H.Teo, "Concurrent multiband digital outphasing transmitter architecture using multidimensional power coding," IEEE Trans.Microw. Theory Techn., vol. 63,no. 2, pp. 598-613,Feb. 2015.

[24] D. Markert, X. Yu, H. Heimpel, and G. Fischer, "An all-digital, single-bit RF transmitter for massive MIMO," IEEE Trans. Circuits Syst. I, Reg. Papers, vol. 64, no. 3, pp. 696-704,Mar.2017.

[25] J.Yang,S.Y.Yang,Z.H.Chen, and X. Y. Zhang, "An agile LUT-based all-digital transmitter," IEEE Trans. Circuits Syst. I, Reg. Papers, vol.67, no. 12,pp. 5550-5560,Dec.2020.

[26] P. M. Aziz, H. V. Sorensen, and J. van der Spiegel, "An overview of sigma-delta converters," IEEE Signal Process. Mag., vol. 13,no. 1, pp.61-84,Jan.1996.

[27] S.Y.Yang,J. Yang,L.Y.Huang, J.L. Bai,and X. Y. Zhang, "A dual-band RF all-digital transmitter based on MPWM encoding," IEEE Trans. Microw.Theory Techn., vol. 70, no. 3, pp. 1745-1756, Mar. 2022.

[28] S. S. Pereira, L. F. Almeida, R. F. Cordeiro, A. S. R. Oliveira, P.P. Monteiro, and N. B. Carvalho, "Scalable resource optimized LUT-based all-digital transmitter," IEEE Trans. Circuits Syst. I, Reg.Papers, vol. 70, no. 8, pp. 3212-3220,Aug. 2023.

[29] S. Kirkpatrick, C. D. Gelatt, and M. P. Vecchi, "Optimization by simulated annealing," Science, vol. 220, pp. 671-680, May 1983,doi: 10.1126/science.220.4598.671.

[30] A.FFilip, "Linear approximations to $\sqrt {x^{2}+y^{2}}$ having equiripple error characteristics," IEEE Trans. Audio Electroacoustics, vol.AE-21,no.6, pp. 554-556,Dec.1973.

[31] H. A. Mahmoud and H. Arslan,"Error vector magnitude to SNR conversion for nondata-aided receivers," IEEE Trans. Wireless Commun., vol. 8, no.5,pp.2694-2704,May 2009.

**Yujie** **Xian** received the B.E. degree from the University of Electronic Science and Technology of China (UESTC) in 2023, where he is currently pursuing the M.Eng. degree under the guidance of Shang Ma. His research interests include digital transmitters, signal processing, and VLSI design.


![](https://web-api.textin.com/ocr_image/external/1d48fc2ec7d359a9.jpg)

Kai Gao received the B.Eng. and M.Eng.degrees from the University of Electronic Science and Tech-nology of China (UESTC), Chengdu, in 2021 and 2024,where he is currently pursuing the Ph.D. degree. HHis current research interests include digital communication circuits and RF fingerprints.


![](https://web-api.textin.com/ocr_image/external/d813967574073530.jpg)


![](https://web-api.textin.com/ocr_image/external/0eecbf9241421bcf.jpg)

**Shang** **Ma** received the B.E. degree from the Southwest University of Science and Technol-ogy,Mianyang, China, in 2001, and the M.Eng. and Ph.D. degrees from the University of Elec-tronic Science and Technology of China (UESTC), Chengdu, China, in 2006 and 2009, respectively. From 2001 to 2010, he was with the Southwest University of Science and Technology. He has been with UESTC since 2010. From 2013 to 2014, he was a Visiting Scholar with the University of Florida, USA. He is currently a Professor with UESTC. His

research interests include computer arithmetic, signal processing, and VLSI design.

Kaijiang Li received the B.E. and M.E. degrees from the University of Electronic Science and Tech-nology of China (UESTC) in 2021 and 2024, respectively, where he is currently pursuing the Ph.D.degree. His current research interests include time synchronization and range measurement for UAVs.


![](https://web-api.textin.com/ocr_image/external/841848740103cec7.jpg)

Jian Wang received the B.E. and M.Eng. degrees from thme University of Electronic Science and Tech-nology of China (UESTC), Chengdu, China, in 2001 and 2004, respectively.Since 2001,he has been an Engineer. He is currently a Senior Engineer. His current research interests include signal processing for satellite communication.


![](https://web-api.textin.com/ocr_image/external/bd90a826e765222e.jpg)

<!-- Authorized licensed use limited to: Nanjing University of Information Science and Technology. Downloaded on September 03,2025 at 07:16:48 UTC from IEEE Xplore. Restrictions apply. -->

