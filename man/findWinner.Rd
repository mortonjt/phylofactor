% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/findWinner.R
\name{findWinner}
\alias{findWinner}
\title{Internal PhyloRegression function for finding the winning edge.}
\usage{
findWinner(nset, tree_map, treeList, treetips, choice, smallglm = F,
  frmla = NULL, xx = NULL, choice.fcn = NULL, ...)
}
\arguments{
\item{nset}{set of nodes}

\item{tree_map}{mapping cumulative number of nodes in treeList, used to map elements of nset to their appropriate tree in treeList.}

\item{treeList}{list containing disjoint trees from phylofactor / PhyCA}

\item{treetips}{number of tips in each tree}

\item{choice}{string indicating how we choose the winner. Must be either \code{'var'}, \code{'F'}, or \code{'phyca'}}

\item{smallglm}{Logical - whether or not to use regular \code{glm}. if smallglm=F, will use \code{\link{bigglm}} from the \code{\link{biglm}} package.}

\item{choice.fcn}{See \code{\link{PhyloFactor}}}

\item{LogData}{logarithm of data - taking logarithm beforehand allows us to compute the logarithm of big datasets only once.}
}
\description{
Internal PhyloRegression function for finding the winning edge.
}
