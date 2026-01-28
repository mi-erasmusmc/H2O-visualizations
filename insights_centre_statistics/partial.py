"""
This file contains all partial algorithm functions, that are normally executed
on all nodes for which the algorithm is executed.

The results in a return statement are sent to the vantage6 server (after
encryption if that is enabled). From there, they are sent to the partial task
or directly to the user (if they requested partial results).
"""
import pandas as pd
from typing import Any

from vantage6.algorithm.tools.util import info, warn, error
from vantage6.algorithm.tools.decorators import algorithm_client
from vantage6.algorithm.tools.decorators import database_connection
from vantage6.algorithm.client import AlgorithmClient


if os.environ.get('IGNORE_R_IMPORTS', False):
    ic_statistics_r = None
else:
    ic_statistics_r = importr('h2o.insightscentre')

@database_connection(types=["OMOP"], include_metadata=True)
@algorithm_client
def partial(
    client: AlgorithmClient
) -> Any:

    """ Decentral part of the algorithm """
    # TODO this is a simple example to show you how to return something simple.
    # Replace it by your own code
    info("Running the pipeline")
    result = ic_statistics_r.run_pipeline()

    # Return results to the vantage6 server.
    # TODO make sure no privacy sensitive data is shared
    return result.to_dict()

# TODO Feel free to add more partial functions here.
