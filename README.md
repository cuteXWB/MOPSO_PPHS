# MOPSO_PPHS
Algorithm code and some experimental results
@article{ZHAO2026,
title = {Multi-objective particle swarm optimization with prior-posterior knowledge guidance and hybrid environmental selection for feature selection},
journal = {Journal of Advanced Research},
year = {2026},
issn = {2090-1232},
doi = {https://doi.org/10.1016/j.jare.2026.10.050},
url = {https://www.sciencedirect.com/science/article/pii/S2090123226008398},
author = {Yaojie Zhao and Ruixuan Liao and Jinpeng Huang and Yujun Cai and Huiling Chen},
keywords = {Multi-objective feature selection, Particle swarm optimization, Feature weight classification},
abstract = {Introduction
Multi-objective feature selection (MOFS) aims to select compact feature subsets while maintaining classification accuracy. For high-dimensional data, traditional multi-objective particle swarm optimization (MOPSO) is often limited by random initialization, weak binary-space exploitation, and biased environmental selection during evolutionary search.
Objectives
This study proposes an improved MOPSO framework to better balance classification accuracy and subset sparsity while maintaining convergence, diversity, and search efficiency.
Methods
We propose MOPSO_PPHS, a MOPSO-based framework integrating prior-posterior knowledge guidance, a V-shaped transfer operator, and hybrid environmental selection. Unlike methods relying mainly on static feature scores or elite Pareto solutions, the proposed guidance mechanism combines filter-based prior information with evolution-derived posterior feedback to support sparse initialization and feature-level mutation. The V-shaped operator improves binary position updating, while the hybrid environmental selection strategy preserves sparse and accurate boundary solutions to maintain Pareto-front coverage. Experiments were conducted on 20 benchmark datasets against eight representative algorithms using HV, IGD, MER, and ART.
Results
MOPSO_PPHS achieves the best average ranks on HV and IGD among the compared algorithms, indicating better convergence and Pareto-front coverage. It obtains low MER on high-dimensional datasets, with zero classification error on several datasets, while maintaining low ART.
Conclusion
MOPSO_PPHS improves traditional MOPSO by combining knowledge-guided search, binary-space search enhancement, and boundary-aware environmental selection. The proposed framework provides an effective approach for high-dimensional MOFS, with potential use in medical gene screening and related high-dimensional classification tasks.}
}
