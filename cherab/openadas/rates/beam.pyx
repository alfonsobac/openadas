# Copyright 2014-2017 United Kingdom Atomic Energy Authority
#
# Licensed under the EUPL, Version 1.1 or – as soon they will be approved by the
# European Commission - subsequent versions of the EUPL (the "Licence");
# You may not use this work except in compliance with the Licence.
# You may obtain a copy of the Licence at:
#
# https://joinup.ec.europa.eu/software/page/eupl5
#
# Unless required by applicable law or agreed to in writing, software distributed
# under the Licence is distributed on an "AS IS" basis, WITHOUT WARRANTIES OR
# CONDITIONS OF ANY KIND, either express or implied.
#
# See the Licence for the specific language governing permissions and limitations
# under the Licence.

# cython: language_level=3

from cherab.core.utility.conversion import Cm3ToM3, PerCm3ToPerM3, PhotonToJ

cimport cython

from cherab.core.math cimport Interpolate1DCubic, Interpolate2DCubic


cdef class BeamStoppingRate(CoreBeamStoppingRate):
    """
    The beam stopping coefficient interpolation class.

    :param data: A dictionary holding the beam coefficient data.
    :param extrapolate: Set to True to enable extrapolation, False to disable (default).
    """

    @cython.cdivision(True)
    def __init__(self, dict data, bint extrapolate=False):

        self.raw_data = data

        # pre-convert data to m^3/s from cm^3/s prior to interpolation
        eb = data["EB"]                                     # eV/amu
        dt = PerCm3ToPerM3.to(data["DT"])                   # m^-3
        tt = data["TT"]                                     # eV

        sv = Cm3ToM3.to(data["SV"])                         # m^3/s
        svt = data["SVT"] / data["SVREF"]                   # dimensionless

        # interpolate
        self._npl_eb = Interpolate2DCubic(eb, dt, sv, tolerate_single_value=True, extrapolate=extrapolate, extrapolation_type="quadratic")
        self._tp = Interpolate1DCubic(tt, svt, tolerate_single_value=True, extrapolate=extrapolate, extrapolation_type="quadratic")

    cpdef double evaluate(self, double energy, double density, double temperature) except? -1e999:
        """
        Interpolates and returns the beam coefficient for the supplied parameters.

        If the requested data is out-of-range then the call with throw a ValueError exception.

        :param energy: Interaction energy in eV/amu.
        :param density: Target electron density in m^-3
        :param temperature: Target temperature in eV.
        :return: The beam stopping coefficient in m^3.s^-1
        """

        cdef double val

        val = self._npl_eb.evaluate(energy, density)
        if val < 0:
            return 0.0

        val *= self._tp.evaluate(temperature)
        if val < 0:
            return 0.0

        return val


cdef class BeamPopulationRate(CoreBeamPopulationRate):
    """
    The beam population coefficient interpolation class.

    :param data: A dictionary holding the beam coefficient data.
    :param extrapolate: Set to True to enable extrapolation, False to disable (default).
    """

    @cython.cdivision(True)
    def __init__(self, dict data, bint extrapolate=False):

        self.raw_data = data

        # pre-convert data to m^3/s from cm^3/s prior to interpolation
        eb = data["EB"]                                     # eV/amu
        dt = PerCm3ToPerM3.to(data["DT"])                   # m^-3
        tt = data["TT"]                                     # eV

        sv = data["SV"]                                     # dimensionless
        svt = data["SVT"] / data["SVREF"]                   # dimensionless

        # interpolate
        self._npl_eb = Interpolate2DCubic(eb, dt, sv, tolerate_single_value=True, extrapolate=extrapolate, extrapolation_type="quadratic")
        self._tp = Interpolate1DCubic(tt, svt, tolerate_single_value=True, extrapolate=extrapolate, extrapolation_type="quadratic")

    cpdef double evaluate(self, double energy, double density, double temperature) except? -1e999:
        """
        Interpolates and returns the beam coefficient for the supplied parameters.

        If the requested data is out-of-range then the call with throw a ValueError exception.

        :param energy: Interaction energy in eV/amu.
        :param density: Target electron density in m^-3
        :param temperature: Target temperature in eV.
        :return: The beam population coefficient in dimensionless units.
        """

        cdef double val

        val = self._npl_eb.evaluate(energy, density)
        if val < 0:
            return 0.0

        val *= self._tp.evaluate(temperature)

        if val < 0:
            return 0.0

        return val


cdef class BeamEmissionRate(CoreBeamEmissionRate):
    """
    The beam emission coefficient interpolation class.

    :param data: A dictionary holding the beam coefficient data.
    :param extrapolate: Set to True to enable extrapolation, False to disable (default).
    """

    @cython.cdivision(True)
    def __init__(self, dict data, double wavelength, bint extrapolate=False):

        self.raw_data = data

        # pre-convert data to m^3/s from cm^3/s prior to interpolation
        eb = data["EB"]                                     # eV/amu
        dt = PerCm3ToPerM3.to(data["DT"])                   # m^-3
        tt = data["TT"]                                     # eV

        sv = PhotonToJ.to(Cm3ToM3.to(data["SV"]), wavelength) # W.m^3/s
        svt = data["SVT"] / data["SVREF"]                     # dimensionless

        # interpolate
        self._npl_eb = Interpolate2DCubic(eb, dt, sv, tolerate_single_value=True, extrapolate=extrapolate, extrapolation_type="quadratic")
        self._tp = Interpolate1DCubic(tt, svt, tolerate_single_value=True, extrapolate=extrapolate, extrapolation_type="quadratic")

    cpdef double evaluate(self, double energy, double density, double temperature) except? -1e999:
        """
        Interpolates and returns the beam coefficient for the supplied parameters.

        If the requested data is out-of-range then the call with throw a ValueError exception.

        :param energy: Interaction energy in eV/amu.
        :param density: Target electron density in m^-3
        :param temperature: Target temperature in eV.
        :return: The beam emission coefficient in m^3.s^-1
        """

        cdef double val

        val = self._npl_eb.evaluate(energy, density)
        if val < 0:
            return 0.0

        val *= self._tp.evaluate(temperature)
        if val < 0:
            return 0.0

        return val
